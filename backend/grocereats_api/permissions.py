from rest_framework.permissions import BasePermission

class IsSeller(BasePermission):
    """
    Allows access only to users with the 'seller' role.
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'seller'


class IsBuyer(BasePermission):
    """
    Allows access only to users with the 'buyer' role.
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'customer'
