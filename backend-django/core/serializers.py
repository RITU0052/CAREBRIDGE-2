from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from .models import User, ParentProfile, Medicine, MedicineLog


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField()
    email = serializers.EmailField()
    phone = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, validators=[validate_password])
    role = serializers.ChoiceField(choices=['child', 'parent'])

    # Parent-only optional fields
    age = serializers.IntegerField(required=False, allow_null=True)
    blood_group = serializers.CharField(required=False, allow_blank=True)
    medical_history = serializers.CharField(required=False, allow_blank=True)
    child_email = serializers.EmailField(required=False, allow_blank=True)

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('An account with this email already exists')
        return value

    def create(self, validated_data):
        name = validated_data['name']
        email = validated_data['email']
        role = validated_data['role']

        user = User.objects.create_user(
            username=email,  # keep it simple: username = email
            email=email,
            password=validated_data['password'],
            first_name=name,
            phone=validated_data.get('phone', ''),
            role=role,
        )

        if role == 'parent':
            child = None
            child_email = validated_data.get('child_email')
            if child_email:
                child = User.objects.filter(email=child_email, role='child').first()

            ParentProfile.objects.create(
                user=user,
                child=child,
                age=validated_data.get('age'),
                blood_group=validated_data.get('blood_group') or None,
                medical_history=validated_data.get('medical_history') or None,
            )

        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data['email'], password=data['password'])
        if not user:
            raise serializers.ValidationError('Invalid email or password')
        data['user'] = user
        return data


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(read_only=True)
    user_id = serializers.IntegerField(source='id', read_only=True)

    class Meta:
        model = User
        fields = ['id', 'user_id', 'name', 'email', 'phone', 'role']


class MedicineLogStatusSerializer(serializers.Serializer):
    medicine_id = serializers.IntegerField()
    status = serializers.ChoiceField(choices=['pending', 'taken', 'skipped'])


class AddMedicineSerializer(serializers.Serializer):
    parent_profile_id = serializers.IntegerField()
    medicine_name = serializers.CharField()
    dose = serializers.CharField(required=False, allow_blank=True)
    time_of_day = serializers.CharField(required=False, allow_blank=True)
