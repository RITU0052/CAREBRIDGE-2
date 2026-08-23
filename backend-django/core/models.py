from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Custom user model. We keep Django's built-in auth (username, password
    hashing, etc.) but add a 'role' field and make email the login identifier.
    """
    ROLE_CHOICES = [
        ('child', 'Child (Caregiver)'),
        ('parent', 'Parent (Monitored)'),
        ('doctor', 'Doctor'),
        ('caregiver', 'Caregiver/Nurse'),
        ('admin', 'Administrator'),
    ]

    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']  # Django still wants a username internally

    def __str__(self):
        return f'{self.get_full_name() or self.username} ({self.role})'

    @property
    def name(self):
        return self.get_full_name() or self.username


class ParentProfile(models.Model):
    """Health profile for a monitored parent, linked to the child (caregiver) who manages them."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='parent_profile')
    child = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='linked_parents'
    )
    age = models.IntegerField(null=True, blank=True)
    blood_group = models.CharField(max_length=5, blank=True, null=True)
    medical_history = models.TextField(blank=True, null=True)
    doctor = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='patients'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Profile of {self.user.name}'


class Medicine(models.Model):
    parent_profile = models.ForeignKey(ParentProfile, on_delete=models.CASCADE, related_name='medicines')
    medicine_name = models.CharField(max_length=150)
    dose = models.CharField(max_length=50, blank=True, null=True)
    time_of_day = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.medicine_name


class MedicineLog(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('taken', 'Taken'),
        ('skipped', 'Skipped'),
    ]

    medicine = models.ForeignKey(Medicine, on_delete=models.CASCADE, related_name='logs')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    log_date = models.DateField()
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('medicine', 'log_date')

    def __str__(self):
        return f'{self.medicine.medicine_name} - {self.log_date} - {self.status}'
