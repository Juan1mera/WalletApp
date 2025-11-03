// custom_number_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wallet_app/core/constants/colors.dart';

class CustomNumberField extends StatefulWidget {
  final String currency;
  final Function(double)? onChanged;
  final TextEditingController? controller;
  final String? hintText;

  const CustomNumberField({
    super.key,
    required this.currency,
    this.onChanged,
    this.controller,
    this.hintText,
  });

  @override
  State<CustomNumberField> createState() => _CustomNumberFieldState();
}

class _CustomNumberFieldState extends State<CustomNumberField>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  NumberFormat? _formatter;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _setupFormatter();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CustomNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency) {
      _setupFormatter();
    }
  }

  void _setupFormatter() {
    final locale = _getLocaleForCurrency(widget.currency);
    _formatter = NumberFormat.decimalPattern(locale);
    _formatter!.minimumFractionDigits = 2;
    _formatter!.maximumFractionDigits = 2;
  }

  String _getLocaleForCurrency(String currency) {
    const Map<String, String> localeMap = {
      'USD': 'en_US',
      'EUR': 'es_ES',
      'GBP': 'en_GB',
      'JPY': 'ja_JP',
      'MXN': 'es_MX',
      'BRL': 'pt_BR',
      'INR': 'en_IN',
      'COP': 'es_CO',
      'RUB': 'ru_RU',
    };
    return localeMap[currency] ?? 'en_US';
  }

  String _getCurrencySymbol(String currency) {
    const Map<String, String> symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'MXN': r'$',
      'BRL': r'R$',
      'INR': '₹',
      'COP': r'$',
      'RUB': '₽',
    };
    return symbols[currency] ?? currency;
  }

  void _onTextChanged() {
    if (_isUpdating) return;

    final text = _controller.text;
    
    // Extraer solo números
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // Si está vacío, limpiar todo
    if (digitsOnly.isEmpty) {
      _isUpdating = true;
      _controller.text = '';
      _controller.selection = const TextSelection.collapsed(offset: 0);
      _isUpdating = false;
      widget.onChanged?.call(0.0);
      return;
    }

    // Convertir a número decimal (dividir entre 100 para obtener centavos)
    final value = double.parse(digitsOnly) / 100.0;

    // Formatear con separadores de miles y decimales
    final formatted = _formatter!.format(value);

    // Actualizar el campo
    _isUpdating = true;
    _controller.text = formatted;
    
    // Colocar cursor al final siempre
    _controller.selection = TextSelection.collapsed(offset: formatted.length);
    _isUpdating = false;

    // Notificar cambio
    widget.onChanged?.call(value);
  }

  void _onFocusChange(bool hasFocus) {
    hasFocus ? _animationController.forward() : _animationController.reverse();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = AppColors.verde;
    final Color backgroundColor = baseColor.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Focus(
              onFocusChange: _onFocusChange,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  color: AppColors.verde,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: baseColor.withValues(alpha: .6)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      _getCurrencySymbol(widget.currency),
                      style: const TextStyle(
                        color: AppColors.verde,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}