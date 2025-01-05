from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from .models import Shop, Stock, Order, OrderItem, SubCategory, Category, PickupPoint
from .serializers import ShopSerializer, StockSerializer, OrderSerializer, UserSerializer, SubCategorySerializer, \
    CategorySerializer, RatingSerializer, PickupPointSerializer, OrderSimpleSerializer
from .permissions import IsSeller, IsBuyer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError


@api_view(['GET'])
@permission_classes([AllowAny])  # Public access
def index(request):
    return JsonResponse({'message': 'Welcome to GrocerEats API!'}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])  # Public access
def register(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()  # The hashing is handled inside the serializer
        return Response({'message': 'User registered successfully!'}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])  # Ensure only authenticated users can log out
def logout_user(request):
    try:
        # Extract the refresh token from the request body
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response({'error': 'Refresh token is required for logout'}, status=status.HTTP_400_BAD_REQUEST)

        # Blacklist the refresh token to invalidate it
        token = RefreshToken(refresh_token)
        token.blacklist()

        return Response({'message': 'Logged out successfully!'}, status=status.HTTP_200_OK)

    except TokenError:
        return Response({'error': 'Invalid or expired refresh token'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': 'An error occurred while logging out'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Both sellers and customers
def list_orders(request):
    if request.user.role == 'customer':  # Customers
        orders_list = Order.objects.filter(buyer=request.user).exclude(status='active')
    elif request.user.role == 'seller':  # Sellers
        orders_list = Order.objects.filter(shop__seller=request.user).exclude(status='active')
    else:
        return Response({'error': 'Invalid user role'}, status=status.HTTP_403_FORBIDDEN)

    serializer = OrderSimpleSerializer(orders_list, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsBuyer])  # Customers only
def place_order(request):
    if request.user.role != 'customer':
        return Response({'error': 'Only customers can place orders.'}, status=status.HTTP_403_FORBIDDEN)

    serializer = OrderSerializer(data=request.data)
    if serializer.is_valid():
        items_data = serializer.validated_data['items']
        total_price = 0

        # Process each order item
        for item_data in items_data:
            stock = item_data['stock']
            quantity = item_data['quantity']

            # Check stock availability
            if stock.quantity < quantity:
                return Response(
                    {'error': f'Not enough stock for {stock.name}. Available: {stock.quantity}.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Deduct stock
            stock.quantity -= quantity
            stock.save()
            price_at_purchase = stock.unit_price  # Assuming Stock has a `unit_price` field
            total_price += price_at_purchase * quantity

        # Create the order and order items
        order = serializer.save(buyer=request.user, total_price=total_price)

        # Save each order item
        for item_data in items_data:
            OrderItem.objects.create(
                order=order,
                stock=item_data['stock'],
                quantity=item_data['quantity'],
                price_at_purchase=item_data['stock'].unit_price
            )

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsBuyer])  # Customers only
def get_active_order(request):
    """
    Retrieve the active order for the authenticated customer.
    """
    try:
        # Retrieve the active order for the customer
        order = Order.objects.get(buyer=request.user, status='active')
        serializer = OrderSerializer(order)
        return Response(serializer.data, status=status.HTTP_200_OK)

    except Order.DoesNotExist:
        return Response({'error': 'No active order found.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])  # Both sellers and customers
def order_detail(request, id):
    try:
        order = Order.objects.get(id=id)
    except Order.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':  # View order details
        if request.user != order.buyer and request.user != order.shop.seller:
            return Response({'error': 'You are not authorized to view this order.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = OrderSerializer(order)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'PATCH':  # Update order status
        if request.user.role == 'seller' and request.user == order.shop.seller:
            serializer = OrderSerializer(order, data=request.data, partial=True)
            if serializer.is_valid():
                new_status = serializer.validated_data.get('status')
                if new_status == 'cancelled' and order.status == 'pending':
                    # Restore stock for cancelled orders
                    for item in order.items.all():
                        item.stock.quantity += item.quantity
                        item.stock.save()

                order = serializer.save()
                return Response(OrderSerializer(order).data, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        elif request.user.role == 'customer' and request.user == order.buyer:
            # Customers can cancel only pending orders
            if order.status != 'pending':
                return Response({'error': 'You can only cancel orders in pending status.'}, status=status.HTTP_403_FORBIDDEN)

            serializer = OrderSerializer(order, data={'status': 'cancelled'}, partial=True)
            if serializer.is_valid():
                # Restore stock for cancelled orders
                for item in order.items.all():
                    item.stock.quantity += item.quantity
                    item.stock.save()

                order = serializer.save()
                return Response(OrderSerializer(order).data, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    return Response({'error': 'Unauthorized action.'}, status=status.HTTP_403_FORBIDDEN)


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsBuyer])  # Customers only
def add_item_to_order(request):
    """
    Add a stock item to an active order. If no active order exists, create one.
    """
    print(request.data)
    try:
        shop_id = request.data.get('shop_id')
        stock_id = request.data.get('stock_id')
        quantity = request.data.get('quantity')

        if not all([shop_id, stock_id, quantity]):
            return Response({'error': 'shop_id, stock_id, and quantity are required.'}, status=status.HTTP_400_BAD_REQUEST)

        shop = Shop.objects.get(id=shop_id)
        stock = Stock.objects.get(id=stock_id)

        # Ensure enough stock is available
        if stock.quantity < int(quantity):
            return Response({'error': f'Not enough stock available for {stock.name}. Only {stock.quantity} left.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check for an existing active order
        active_order = Order.objects.filter(buyer=request.user, status='active').first()

        if active_order:
            # If an active order exists, ensure it is for the same shop
            if active_order.shop.id != shop.id:
                return Response(
                    {'error': 'You cannot add items from a different shop to your active order. Please submit or cancel your active order first.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        else:
            # Create a new active order if none exists
            active_order = Order.objects.create(
                buyer=request.user,
                shop=shop,
                status='active',
                total_price=0
            )

        # Add item to order
        order_item, item_created = OrderItem.objects.get_or_create(
            order=active_order,
            stock=stock,
            defaults={
                'quantity': quantity,
                'price_at_purchase': stock.price_per_unit
            }
        )

        if not item_created:
            # If the item already exists in the order, update the quantity
            order_item.quantity += int(quantity)
            order_item.save()

        # Deduct stock quantity
        stock.quantity -= int(quantity)
        stock.save()

        # Update total price of the order
        active_order.total_price += stock.price_per_unit * int(quantity)
        active_order.save()

        return Response({
            'message': 'Item added to order successfully.',
            'order_id': active_order.id,
            'order_item_id': order_item.id,
            'quantity': order_item.quantity,
        }, status=status.HTTP_200_OK)

    except Shop.DoesNotExist:
        return Response({'error': 'Shop not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Stock.DoesNotExist:
        return Response({'error': 'Stock not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(e)
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated, IsBuyer])  # Only customers
def delete_item_from_order(request, order_item_id):
    try:
        # Retrieve the order item
        order_item = OrderItem.objects.get(id=order_item_id, order__buyer=request.user, order__status='active')
    except OrderItem.DoesNotExist:
        return Response({'error': 'Order item not found or not part of an active order.'}, status=status.HTTP_404_NOT_FOUND)

    # Restore stock quantity
    stock = order_item.stock
    stock.quantity += int(order_item.quantity)
    stock.save()

    # Update the order total price
    order = order_item.order
    order.total_price -= int(order_item.quantity) * int(order_item.price_at_purchase)
    order.save()

    # Delete the order item
    order_item.delete()

    return Response({'message': 'Item removed from order successfully.'}, status=status.HTTP_200_OK)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated, IsBuyer])  # Only customers
def edit_item_quantity(request, order_item_id):
    try:
        # Retrieve the order item
        order_item = OrderItem.objects.get(id=order_item_id, order__buyer=request.user, order__status='active')
    except OrderItem.DoesNotExist:
        return Response({'error': 'Order item not found or not part of an active order.'}, status=status.HTTP_404_NOT_FOUND)

    # Parse the new quantity
    new_quantity = request.data.get('quantity')
    if not new_quantity or int(new_quantity) <= 0:
        return Response({'error': 'Quantity must be a positive number.'}, status=status.HTTP_400_BAD_REQUEST)

    new_quantity = int(new_quantity)
    current_quantity = int(order_item.quantity)
    stock = order_item.stock

    # Calculate the quantity difference
    quantity_difference = new_quantity - current_quantity

    # Ensure sufficient stock if increasing quantity
    if quantity_difference > 0 and stock.quantity < quantity_difference:
        return Response({'error': f'Not enough stock for {stock.name}. Available: {stock.quantity}.'}, status=status.HTTP_400_BAD_REQUEST)

    # Update stock quantity
    stock.quantity -= quantity_difference
    stock.save()

    # Update order item quantity
    order_item.quantity = new_quantity
    order_item.save()

    # Update the order total price
    order = order_item.order
    order.total_price += quantity_difference * int(order_item.price_at_purchase)
    order.save()

    return Response({'message': 'Item quantity updated successfully.', 'order_item': {
        'id': order_item.id,
        'stock': order_item.stock.name,
        'quantity': order_item.quantity,
        'price_at_purchase': order_item.price_at_purchase
    }}, status=status.HTTP_200_OK)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated, IsBuyer])  # Customers only
def submit_order(request, id):
    """
    Submit an active order by changing its status to pending.
    """
    try:
        order = Order.objects.get(id=id, buyer=request.user, status='active')
        order.status = 'pending'
        order.save()
        return Response({'message': 'Order submitted successfully!'}, status=status.HTTP_200_OK)

    except Order.DoesNotExist:
        return Response({'error': 'Active order not found.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated, IsSeller])  # Sellers only
def confirm_order(request, id):
    """
    Confirm a pending order by changing its status to completed.
    """
    try:
        order = Order.objects.get(id=id, shop__seller=request.user, status='pending')
        order.status = 'completed'
        order.save()
        return Response({'message': 'Order confirmed successfully!'}, status=status.HTTP_200_OK)

    except Order.DoesNotExist:
        return Response({'error': 'Pending order not found.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def cancel_order(request, id):
    """
    Cancel a pending order by changing its status to cancelled and restoring stock quantities.
    """
    try:
        order = Order.objects.get(id=id, buyer=request.user)
        if order.status != 'pending' and order.status != 'active':
            return Response({'error': 'Only active and pending orders can be cancelled.'}, status=status.HTTP_403_FORBIDDEN)
        # Restore stock quantities
        for item in order.items.all():
            item.stock.quantity += item.quantity
            item.stock.save()

        order.status = 'cancelled'
        order.save()
        return Response({'message': 'Order cancelled successfully!'}, status=status.HTTP_200_OK)

    except Order.DoesNotExist:
        return Response({'error': 'Pending order not found.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsSeller])  # Only sellers
def add_stock(request):
    try:
        # Ensure the seller has a shop
        shop = Shop.objects.get(seller=request.user)
    except Shop.DoesNotExist:
        return Response(
            {'error': 'You do not have an associated shop.'},
            status=status.HTTP_403_FORBIDDEN
        )

    print(request.data)
    # Create a new stock entry associated with the seller's shop
    serializer = StockSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(shop=shop)  # Automatically associate with the seller's shop
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated, IsSeller])  # Only sellers
def remove_stock(request, id):
    try:
        # Ensure the stock belongs to the seller's shop
        stock = Stock.objects.get(id=id, shop__seller=request.user)
    except Stock.DoesNotExist:
        return Response(
            {'error': 'Stock entry not found or does not belong to your shop.'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Delete the stock entry
    stock.delete()
    return Response({'message': 'Stock entry deleted successfully.'}, status=status.HTTP_200_OK)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated, IsSeller])  # Only sellers
def edit_stock(request, id):
    try:
        # Ensure the stock belongs to the seller's shop
        stock = Stock.objects.get(id=id, shop__seller=request.user)
    except Stock.DoesNotExist:
        return Response(
            {'error': 'Stock entry not found or does not belong to your shop.'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Partially update the stock entry
    serializer = StockSerializer(stock, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def view_stocks(request, id):
    try:
        # Retrieve the shop by ID
        shop = Shop.objects.get(id=id)
    except Shop.DoesNotExist:
        return Response({'error': 'Shop not found.'}, status=status.HTTP_404_NOT_FOUND)

    # Retrieve the stock entries for the specified shop
    stocks = Stock.objects.filter(shop=shop)
    serializer = StockSerializer(stocks, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def shops(request):
    if request.method == 'GET':  # All authenticated users can view shops
        shops = Shop.objects.all()
        serializer = ShopSerializer(shops, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST' and request.user.role == 'seller':  # Only sellers can create shops
        print(request.data)
        serializer = ShopSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(seller=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    return Response({'error': 'Only sellers can add shops'}, status=status.HTTP_403_FORBIDDEN)

@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated, IsSeller])  # Only sellers
def manage_shop(request):
    try:
        # Ensure the seller has a shop
        shop = Shop.objects.get(seller=request.user)
    except Shop.DoesNotExist:
        return Response(
            {'error': 'You do not have an associated shop.'},
            status=status.HTTP_403_FORBIDDEN
        )

    if request.method == 'GET':  # Retrieve the seller's shop details
        # Pass the request context to the serializer
        serializer = ShopSerializer(shop, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'PATCH':  # Update the seller's shop details
        # Pass the request context to the serializer
        print(request.data)
        serializer = ShopSerializer(shop, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def rate_user_or_shop(request):
    serializer = RatingSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    order = serializer.validated_data['order_id']
    rating = serializer.validated_data['rating']

    if request.user.role == 'seller':  # Seller rates customer
        if order.shop.seller != request.user:  # Ensure the seller owns the shop
            return Response({'error': 'You can only rate customers from your shop.'}, status=status.HTTP_403_FORBIDDEN)
        if order.status != 'completed':
            return Response({'error': 'You can only rate customers for completed orders.'}, status=status.HTTP_400_BAD_REQUEST)
        order.customer_rating = rating
        order.save()
        order.buyer.update_rating()  # Update the customer's average rating
        return Response({'message': f'Customer rated successfully with {rating}.'}, status=status.HTTP_200_OK)

    elif request.user.role == 'customer':  # Customer rates shop
        if order.buyer != request.user:  # Ensure the order belongs to the customer
            return Response({'error': 'You can only rate shops for your orders.'}, status=status.HTTP_403_FORBIDDEN)
        if order.status != 'completed':
            return Response({'error': 'You can only rate shops for completed orders.'}, status=status.HTTP_400_BAD_REQUEST)
        order.shop_rating = rating
        order.save()
        order.shop.update_rating()  # Update the shop's average rating
        return Response({'message': f'Shop rated successfully with {rating}.'}, status=status.HTTP_200_OK)

    return Response({'error': 'Invalid role for rating.'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def list_subcategories(request):
    subcategories = SubCategory.objects.all()
    serializer = SubCategorySerializer(subcategories, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def list_categories(request):
    categories = Category.objects.all()  # Retrieve all categories
    serializer = CategorySerializer(categories, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsSeller])  # Only sellers
def create_pickup_point(request):
    serializer = PickupPointSerializer(data=request.data)
    print(request.data)
    if serializer.is_valid():
        # Save the pickup point
        pickup_point = serializer.save()
        return Response(
            {
                'message': 'Pickup point created successfully!',
                'pickup_point': serializer.data  # Use the serialized data for response
            },
            status=status.HTTP_201_CREATED
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def list_pickup_points(request):
    pickup_points = PickupPoint.objects.all()  # Retrieve all pickup points
    serializer = PickupPointSerializer(pickup_points, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def profile(request):
    if request.method == 'GET':  # Get user profile
        serializer = UserSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'PATCH':  # Update user profile
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
