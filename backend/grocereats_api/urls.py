from django.urls import path
from . import views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('', views.index, name='index'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', views.register, name='register'),
    path('logout/', views.logout_user, name='logout'),
    path('orders/', views.orders, name='orders'),
    path('orders/<int:id>/', views.order_detail, name='order_detail'),
    path('stocks/', views.view_stocks, name='view_stocks'),
    path('stocks/add/', views.add_stock, name='add_stock'),
    path('shops/', views.shops, name='shops'),
]
