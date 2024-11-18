from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from .models import Shop, Stock, Order, User
from .serializers import ShopSerializer, StockSerializer, OrderSerializer, UserSerializer
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


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def orders(request):
    if request.method == 'GET':
        if request.user.role == 'customer':  # Buyers
            orders_list = Order.objects.filter(buyer=request.user)
        elif request.user.role == 'seller':  # Sellers
            orders_list = Order.objects.filter(shop__seller=request.user)
        else:
            return Response({'error': 'Invalid user role'}, status=status.HTTP_403_FORBIDDEN)
        serializer = OrderSerializer(orders_list, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST' and request.user.role == 'customer':  # Buyers only
        serializer = OrderSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(buyer=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    return Response({'error': 'Only buyers can create orders'}, status=status.HTTP_403_FORBIDDEN)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def order_detail(request, id):
    try:
        order = Order.objects.get(id=id)
    except Order.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':  # Both roles can view orders
        serializer = OrderSerializer(order)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'PATCH' and request.user.role == 'seller':  # Only sellers can update order status
        serializer = OrderSerializer(order, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    return Response({'error': 'Only sellers can update orders'}, status=status.HTTP_403_FORBIDDEN)


@api_view(['POST'])
@permission_classes([IsSeller])  # Only sellers
def add_stock(request):
    try:
        # Ensure the seller has a shop
        shop = Shop.objects.get(seller=request.user)
    except Shop.DoesNotExist:
        return Response(
            {'error': 'You do not have an associated shop.'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Create a new stock entry associated with the seller's shop
    serializer = StockSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(shop=shop)  # Automatically associate with the seller's shop
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Both sellers and buyers
def view_stocks(request):
    shop_id = request.query_params.get('shop_id')
    if shop_id:
        stocks = Stock.objects.filter(shop_id=shop_id)
    else:
        stocks = Stock.objects.all()
    serializer = StockSerializer(stocks, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Buyers and sellers can view shop stocks
def shop_stocks(request, shop_id):
    try:
        shop = Shop.objects.get(id=shop_id)
    except Shop.DoesNotExist:
        return Response({'error': 'Shop not found'}, status=status.HTTP_404_NOT_FOUND)

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
        serializer = ShopSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(seller=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    return Response({'error': 'Only sellers can add shops'}, status=status.HTTP_403_FORBIDDEN)


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
