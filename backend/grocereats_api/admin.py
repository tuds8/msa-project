from django.contrib import admin
from .models import User, PickupPoint, Shop, Stock, Order, OrderItem, Category, SubCategory

# Register models
admin.site.register(User)
admin.site.register(PickupPoint)
admin.site.register(Shop)
admin.site.register(Stock)
admin.site.register(Order)
admin.site.register(OrderItem)
admin.site.register(Category)
admin.site.register(SubCategory)
