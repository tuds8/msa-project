from django.urls import path
from . import views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('', views.index, name='index'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', views.register, name='register'),
    path('logout/', views.logout_user, name='logout'),
    path('orders/', views.list_orders, name='list_orders'),
    path('orders/new/', views.place_order, name='place_order'),
    path('orders/<int:id>/', views.order_detail, name='order_detail'),
    path('stocks/', views.view_stocks, name='view_stocks'),
    path('stocks/add/', views.add_stock, name='add_stock'),
    path('stocks/remove/<int:id>/', views.remove_stock, name='remove_stock'),
    path('stocks/edit/<int:id>/', views.edit_stock, name='edit_stock'),
    path('shops/', views.shops, name='shops'),
    path('shops/update/', views.update_shop, name='update_shop'),
    path('rate/', views.rate_user_or_shop, name='rate_user_or_shop'),
    path('subcategories/', views.list_subcategories, name='list_subcategories'),
    path('categories/', views.list_categories, name='list_categories'),
    path('pickup-points/create/', views.create_pickup_point, name='create_pickup_point'),
    path('pickup-points/', views.list_pickup_points, name='list_pickup_points'),
    path('profile/', views.profile, name='profile'),
]
