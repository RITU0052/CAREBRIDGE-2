from datetime import date

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, ParentProfile, Medicine, MedicineLog
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer,
    AddMedicineSerializer, MedicineLogStatusSerializer,
)


def issue_token(user):
    refresh = RefreshToken.for_user(user)
    refresh['role'] = user.role
    refresh['name'] = user.name
    return str(refresh.access_token)


# ---------------- AUTH ----------------

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    serializer = RegisterSerializer(data=request.data)
    if not serializer.is_valid():
        first_error = next(iter(serializer.errors.values()))[0]
        return Response({'error': str(first_error)}, status=status.HTTP_400_BAD_REQUEST)

    user = serializer.save()
    token = issue_token(user)
    return Response({
        'message': 'Registration successful',
        'token': token,
        'user': UserSerializer(user).data,
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    serializer = LoginSerializer(data=request.data)
    if not serializer.is_valid():
        return Response({'error': 'Invalid email or password'}, status=status.HTTP_401_UNAUTHORIZED)

    user = serializer.validated_data['user']
    token = issue_token(user)
    return Response({
        'message': 'Login successful',
        'token': token,
        'user': UserSerializer(user).data,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    return Response({'user': UserSerializer(request.user).data})


# ---------------- ACCESS CONTROL HELPER ----------------

def can_access_profile(user, parent_profile_id):
    try:
        profile = ParentProfile.objects.get(pk=parent_profile_id)
    except ParentProfile.DoesNotExist:
        return None

    if user.role == 'parent' and profile.user_id == user.id:
        return profile
    if user.role == 'child' and profile.child_id == user.id:
        return profile
    return None


def medicines_today_payload(parent_profile):
    meds = parent_profile.medicines.all().order_by('created_at')
    today = date.today()
    result = []
    for med in meds:
        log = med.logs.filter(log_date=today).first()
        result.append({
            'medicine_id': med.id,
            'medicine_name': med.medicine_name,
            'dose': med.dose,
            'time_of_day': med.time_of_day,
            'status': log.status if log else 'pending',
        })
    return result


# ---------------- CHILD DASHBOARD ----------------

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_parents(request):
    if request.user.role != 'child':
        return Response({'error': 'Only child accounts can access this'}, status=status.HTTP_403_FORBIDDEN)

    profiles = ParentProfile.objects.filter(child=request.user).select_related('user')
    parents = []
    for p in profiles:
        meds = medicines_today_payload(p)
        taken = sum(1 for m in meds if m['status'] == 'taken')
        parents.append({
            'parent_profile_id': p.id,
            'name': p.user.name,
            'email': p.user.email,
            'phone': p.user.phone,
            'age': p.age,
            'blood_group': p.blood_group,
            'medical_history': p.medical_history,
            'medicine_summary': f'{taken}/{len(meds)} taken today',
            'medicines_today': meds,
        })
    return Response({'parents': parents})


# ---------------- PARENT DASHBOARD ----------------

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_dashboard(request):
    if request.user.role != 'parent':
        return Response({'error': 'Only parent accounts can access this'}, status=status.HTTP_403_FORBIDDEN)

    profile = ParentProfile.objects.filter(user=request.user).first()
    if not profile:
        return Response({'error': 'Parent profile not found'}, status=status.HTTP_404_NOT_FOUND)

    return Response({
        'profile': {
            'parent_profile_id': profile.id,
            'user_id': profile.user_id,
            'child_id': profile.child_id,
            'age': profile.age,
            'blood_group': profile.blood_group,
            'medical_history': profile.medical_history,
        },
        'medicines_today': medicines_today_payload(profile),
    })


# ---------------- MEDICINE ----------------

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_medicine(request):
    serializer = AddMedicineSerializer(data=request.data)
    if not serializer.is_valid():
        return Response({'error': 'parent_profile_id and medicine_name are required'}, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data
    profile = can_access_profile(request.user, data['parent_profile_id'])
    if not profile:
        return Response({'error': 'Not authorized for this profile'}, status=status.HTTP_403_FORBIDDEN)

    medicine = Medicine.objects.create(
        parent_profile=profile,
        medicine_name=data['medicine_name'],
        dose=data.get('dose', ''),
        time_of_day=data.get('time_of_day', ''),
    )
    return Response({
        'message': 'Medicine added',
        'medicine': {
            'medicine_id': medicine.id,
            'parent_profile_id': profile.id,
            'medicine_name': medicine.medicine_name,
            'dose': medicine.dose,
            'time_of_day': medicine.time_of_day,
        }
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_medicines(request, parent_profile_id):
    profile = can_access_profile(request.user, parent_profile_id)
    if not profile:
        return Response({'error': 'Not authorized for this profile'}, status=status.HTTP_403_FORBIDDEN)

    return Response({'medicines': medicines_today_payload(profile)})


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_status(request):
    serializer = MedicineLogStatusSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(
            {'error': "medicine_id and a valid status ('taken'/'skipped') are required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    data = serializer.validated_data
    try:
        medicine = Medicine.objects.select_related('parent_profile').get(pk=data['medicine_id'])
    except Medicine.DoesNotExist:
        return Response({'error': 'Medicine not found'}, status=status.HTTP_404_NOT_FOUND)

    profile = can_access_profile(request.user, medicine.parent_profile_id)
    if not profile:
        return Response({'error': 'Not authorized for this profile'}, status=status.HTTP_403_FORBIDDEN)

    log, _ = MedicineLog.objects.update_or_create(
        medicine=medicine,
        log_date=date.today(),
        defaults={'status': data['status']},
    )
    return Response({
        'message': 'Status updated',
        'log': {
            'log_id': log.id,
            'medicine_id': medicine.id,
            'status': log.status,
            'log_date': str(log.log_date),
        }
    })
