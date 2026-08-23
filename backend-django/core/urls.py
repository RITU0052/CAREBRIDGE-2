from django.urls import path
from . import views

urlpatterns = [
    # Auth
    path('auth/register', views.register),
    path('auth/login', views.login),
    path('auth/me', views.me),

    # Parent dashboards
    path('parent/my-parents', views.my_parents),
    path('parent/dashboard', views.my_dashboard),

    # Medicine
    path('medicine', views.add_medicine),
    path('medicine/status', views.update_status),
    path('medicine/<int:parent_profile_id>', views.get_medicines),
]
