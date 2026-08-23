from django.contrib import admin
from .models import User, ParentProfile, Medicine, MedicineLog

admin.site.register(User)
admin.site.register(ParentProfile)
admin.site.register(Medicine)
admin.site.register(MedicineLog)
