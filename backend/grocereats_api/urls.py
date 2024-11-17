from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('register', views.register, name='register'),
    path('login', views.login_user, name='login'),
    path('logout', views.logout_user, name='logout'),
    path('orders', views.orders, name='orders'),
    path('orders/<int:id>', views.order_detail, name='order_detail'),
    path('stocks', views.view_stocks, name='view_stocks'),
    path('stocks/add', views.add_stock, name='add_stock'),
    path('shops', views.shops, name='shops'),
]
