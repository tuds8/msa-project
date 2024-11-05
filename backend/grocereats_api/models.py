from django.db import models
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    ROLE_CHOICES = [
        ('seller', 'Seller'),
        ('customer', 'Customer'),
    ]

    full_name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=13)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    rating = models.DecimalField(max_digits=3, decimal_places=2, null=True, blank=True)

    # Override related_name attributes to prevent clashes
    groups = models.ManyToManyField(
        'auth.Group',
        related_name='custom_user_groups',  # Change this to a unique related name
        blank=True
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='custom_user_permissions',  # Change this to a unique related name
        blank=True
    )

    # Optional fields for custom User model
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'full_name']


class PickupPoint(models.Model):
    id = models.BigAutoField(primary_key=True)
    lat = models.DecimalField(max_digits=9, decimal_places=6)
    long = models.DecimalField(max_digits=9, decimal_places=6)
    name = models.CharField(max_length=255)
    address = models.TextField()


class Shop(models.Model):
    id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=255)
    pickup_point = models.ForeignKey(PickupPoint, on_delete=models.CASCADE, related_name='shops')
    seller = models.OneToOneField(User, on_delete=models.CASCADE, limit_choices_to={'role': 'seller'})


class Stock(models.Model):
    id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=255)
    unit = models.CharField(max_length=50)
    subcategory = models.ForeignKey('SubCategory', on_delete=models.CASCADE)  # Changed to ForeignKey for one-to-many
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name='stocks')
    description = models.TextField(blank=True, null=True)
    photo_url = models.URLField(blank=True, null=True)
    quantity = models.DecimalField(max_digits=10, decimal_places=2)
    timestamp_last_modified = models.DateTimeField(auto_now=True)


class Order(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.BigAutoField(primary_key=True)
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, limit_choices_to={'role': 'customer'}, related_name='orders')
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name='orders')
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    timestamp = models.DateTimeField(auto_now_add=True)


class OrderItem(models.Model):
    id = models.BigAutoField(primary_key=True)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    stock = models.ForeignKey(Stock, on_delete=models.CASCADE)  # Changed to ForeignKey for many-to-one
    quantity = models.DecimalField(max_digits=10, decimal_places=2)
    price_at_purchase = models.DecimalField(max_digits=10, decimal_places=2)


class Category(models.Model):
    id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=255)


class SubCategory(models.Model):
    id = models.BigAutoField(primary_key=True)
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='subcategories')
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
