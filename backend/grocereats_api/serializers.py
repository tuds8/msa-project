from rest_framework import serializers
from .models import User, Shop, Stock, Order, OrderItem, PickupPoint, Category, SubCategory


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)  # Ensure password is write-only

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'phone', 'role', 'rating', 'password']
        read_only_fields = ['id', 'rating']  # Ensure 'id' and 'rating' are not editable

    def create(self, validated_data):
        # Hash the password before saving
        password = validated_data.pop('password')  # Remove the password from validated data
        user = User(**validated_data)  # Create the user instance
        user.set_password(password)  # Hash the password
        user.save()  # Save the user to the database
        return user


class PickupPointSerializer(serializers.ModelSerializer):
    class Meta:
        model = PickupPoint
        fields = ['id', 'lat', 'long', 'name', 'address']
        read_only_fields = ['id']


class ShopSerializer(serializers.ModelSerializer):
    seller = UserSerializer(read_only=True)  # Include seller details as read-only

    class Meta:
        model = Shop
        fields = ['id', 'name', 'pickup_point', 'seller']
        read_only_fields = ['id', 'seller']


class StockSerializer(serializers.ModelSerializer):
    shop = ShopSerializer(read_only=True)  # Include shop details as read-only
    subcategory = serializers.StringRelatedField()  # Serialize subcategory as its name

    class Meta:
        model = Stock
        fields = [
            'id',
            'name',
            'unit',
            'subcategory',
            'shop',
            'description',
            'photo_url',
            'quantity',
            'timestamp_last_modified',
        ]
        read_only_fields = ['id', 'timestamp_last_modified']


class OrderItemSerializer(serializers.ModelSerializer):
    stock = StockSerializer(read_only=True)  # Include stock details as read-only

    class Meta:
        model = OrderItem
        fields = ['id', 'order', 'stock', 'quantity', 'price_at_purchase']
        read_only_fields = ['id']


class OrderSerializer(serializers.ModelSerializer):
    buyer = UserSerializer(read_only=True)  # Include buyer details as read-only
    shop = ShopSerializer(read_only=True)  # Include shop details as read-only
    items = OrderItemSerializer(many=True, read_only=True)  # Include all items in the order

    class Meta:
        model = Order
        fields = ['id', 'buyer', 'shop', 'total_price', 'status', 'timestamp', 'items']
        read_only_fields = ['id', 'timestamp']


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name']
        read_only_fields = ['id']


class SubCategorySerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)  # Include category details as read-only

    class Meta:
        model = SubCategory
        fields = ['id', 'category', 'name', 'description']
        read_only_fields = ['id']
