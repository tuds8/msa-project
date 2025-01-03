from rest_framework import serializers
from .models import User, Shop, Stock, Order, OrderItem, PickupPoint, Category, SubCategory


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)  # Password is required for creation but optional for updates

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'phone', 'role', 'rating', 'password']
        read_only_fields = ['id', 'rating']

    def create(self, validated_data):
        # Ensure password is provided for new users
        password = validated_data.pop('password', None)
        if not password:
            raise serializers.ValidationError({'password': 'Password is required for new users.'})

        # Create user instance and hash password
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        # Handle password updates securely
        password = validated_data.pop('password', None)
        if password:
            instance.set_password(password)  # Securely hash the password

        # Update other fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()
        return instance


class PickupPointSerializer(serializers.ModelSerializer):
    class Meta:
        model = PickupPoint
        fields = ['id', 'name', 'lat', 'long', 'address']
        read_only_fields = ['id']

    def validate(self, data):
        # Validate latitude and longitude ranges
        lat = data.get('lat')
        long = data.get('long')

        if not (-90 <= lat <= 90):
            raise serializers.ValidationError({'lat': 'Latitude must be between -90 and 90.'})
        if not (-180 <= long <= 180):
            raise serializers.ValidationError({'long': 'Longitude must be between -180 and 180.'})

        return data


class ShopSerializer(serializers.ModelSerializer):
    seller = UserSerializer(read_only=True)  # Include seller details as read-only
    pickup_point = serializers.PrimaryKeyRelatedField(queryset=PickupPoint.objects.all())  # Handle pickup_point as ID for writing

    class Meta:
        model = Shop
        fields = ['id', 'name', 'pickup_point', 'seller']
        read_only_fields = ['id', 'seller']

    def to_representation(self, instance):
        """Customize the representation for GET requests to include full pickup_point details."""
        representation = super().to_representation(instance)
        representation['pickup_point'] = PickupPointSerializer(instance.pickup_point).data
        return representation


class RatingSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
    rating = serializers.DecimalField(max_digits=3, decimal_places=2)

    def validate_order_id(self, value):
        try:
            order = Order.objects.get(id=value)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Order does not exist.")
        return order


class StockSerializer(serializers.ModelSerializer):
    shop = ShopSerializer(read_only=True)  # Read-only shop details
    subcategory = serializers.PrimaryKeyRelatedField(queryset=SubCategory.objects.all())  # Allow selecting subcategory
    category = serializers.SerializerMethodField()  # Dynamically include category details in response

    class Meta:
        model = Stock
        fields = [
            'id',
            'name',
            'unit',
            'subcategory',
            'category',  # Dynamically fetched
            'shop',
            'description',
            'photo_url',
            'quantity',
            'timestamp_last_modified',
        ]
        read_only_fields = ['id', 'timestamp_last_modified', 'shop', 'category']

    def get_category(self, obj):
        # Fetch the category via the related subcategory
        return obj.subcategory.category.name


class OrderItemSerializer(serializers.ModelSerializer):
    stock = serializers.PrimaryKeyRelatedField(queryset=Stock.objects.all())  # Allow referencing stock

    class Meta:
        model = OrderItem
        fields = ['id', 'stock', 'quantity', 'price_at_purchase']
        read_only_fields = ['id', 'price_at_purchase']


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)  # Nested serializer for items

    class Meta:
        model = Order
        fields = ['id', 'buyer', 'shop', 'total_price', 'status', 'timestamp', 'items']
        read_only_fields = ['id', 'buyer', 'total_price', 'timestamp', 'status']

    def create(self, validated_data):
        items_data = validated_data.pop('items')
        order = Order.objects.create(**validated_data)
        for item_data in items_data:
            OrderItem.objects.create(order=order, **item_data)
        return order


class SubCategorySerializer(serializers.ModelSerializer):
    category = serializers.StringRelatedField(read_only=True)  # Include category name in response

    class Meta:
        model = SubCategory
        fields = ['id', 'category', 'name', 'description']
        read_only_fields = ['id', 'category']


class CategorySerializer(serializers.ModelSerializer):
    subcategories = SubCategorySerializer(many=True, read_only=True)  # Include subcategories

    class Meta:
        model = Category
        fields = ['id', 'name', 'subcategories']
