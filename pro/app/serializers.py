from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from .models import Clothes, Cart, CartItem, Order, Category
import base64
import re

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ('id', 'name', 'description')

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'password', 'password2', 'email', 'first_name', 'last_name')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True}
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

class ClothesSerializer(serializers.ModelSerializer):
    seller_name = serializers.SerializerMethodField()
    phone_number = serializers.CharField(write_only=True)  # Hide phone number in list view
    category_name = serializers.SerializerMethodField()

    class Meta:
        model = Clothes
        fields = ('id', 'title', 'description', 'price', 'image_base64', 
                 'phone_number', 'is_sold', 'created_at', 'seller', 'seller_name',
                 'category', 'category_name', 'gender')
        read_only_fields = ('seller', 'is_sold', 'created_at')

    def get_seller_name(self, obj):
        return f"{obj.seller.first_name} {obj.seller.last_name}"

    def get_category_name(self, obj):
        return obj.category.name if obj.category else None

    def validate_image_base64(self, value):
        # Check if the string is a valid base64 image
        try:
            # Check if it's a data URL
            if value.startswith('data:image'):
                # Extract the base64 part
                value = value.split(',')[1]
            
            # Try to decode the base64 string
            base64.b64decode(value)
            
            # Check if it's not too large (e.g., max 5MB)
            if len(value) > 5 * 1024 * 1024:  # 5MB in base64
                raise serializers.ValidationError("Image size should not exceed 5MB")
            
            return value
        except Exception as e:
            raise serializers.ValidationError("Invalid base64 image data")

    def create(self, validated_data):
        validated_data['seller'] = self.context['request'].user
        return super().create(validated_data)

class CartItemSerializer(serializers.ModelSerializer):
    clothes = ClothesSerializer(read_only=True)
    clothes_id = serializers.PrimaryKeyRelatedField(
        queryset=Clothes.objects.filter(is_sold=False),
        write_only=True,
        source='clothes'
    )

    class Meta:
        model = CartItem
        fields = ('id', 'clothes', 'clothes_id', 'quantity', 'created_at')
        read_only_fields = ('created_at',)

class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total = serializers.SerializerMethodField()

    class Meta:
        model = Cart
        fields = ('id', 'items', 'total', 'created_at', 'updated_at')
        read_only_fields = ('created_at', 'updated_at')

    def get_total(self, obj):
        return sum(item.clothes.price * item.quantity for item in obj.items.all())

class OrderSerializer(serializers.ModelSerializer):
    cart = CartSerializer(read_only=True)
    cart_id = serializers.PrimaryKeyRelatedField(
        queryset=Cart.objects.all(),
        write_only=True,
        source='cart'
    )
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)

    class Meta:
        model = Order
        fields = (
            'id', 'cart', 'cart_id', 'total_amount', 'status', 'status_display',
            'payment_status', 'payment_status_display', 'shipping_name',
            'shipping_phone', 'shipping_address', 'created_at', 'updated_at',
            'paid_at', 'shipped_at', 'delivered_at'
        )
        read_only_fields = (
            'total_amount', 'status', 'payment_status', 'created_at',
            'updated_at', 'paid_at', 'shipped_at', 'delivered_at'
        ) 