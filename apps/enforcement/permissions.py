from rest_framework import permissions
from apps.common.constants import UserRole

class IsOfficerOrAdmin(permissions.BasePermission):
    """
    Custom permission to only allow officers and admins to access enforcement endpoints.
    """

    def has_permission(self, request, view):
        return (
            request.user and 
            request.user.is_authenticated and 
            request.user.role in [UserRole.OFFICER, UserRole.ADMIN]
        )