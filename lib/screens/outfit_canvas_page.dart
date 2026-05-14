import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/cloth.dart';
import '../services/cloth_service.dart';
import '../services/api_service.dart';
import 'outfit_save_page.dart';



class CanvasItem {
  final Cloth cloth;
  Offset position;
  double scale;
  double rotation; 
  bool flipH;
  bool flipV;
  bool isSelected;

  CanvasItem({
    required this.cloth,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flipH = false,
    this.flipV = false,
    this.isSelected = false,
  });
}



class OutfitCanvasPage extends StatefulWidget {
  const OutfitCanvasPage({super.key});

  @override
  State<OutfitCanvasPage> createState() => _OutfitCanvasPageState();
}

class _OutfitCanvasPageState extends State<OutfitCanvasPage> {
  final ClothService _clothService = ClothService();
  final ApiService _apiService = ApiService();
  final GlobalKey _canvasKey = GlobalKey();

  List<Cloth> _clothes = [];
  final List<CanvasItem> _items = [];
  bool _isLoading = true;
  bool _isCapturing = false;

  
  Color _bgColor = Colors.white;

  
  _ToolPanel _activePanel = _ToolPanel.none;

  
  Offset? _gestureStartFocal;
  double? _gestureStartScale;
  double? _gestureStartRotation;
  Offset? _gestureStartPosition;

  CanvasItem? get _selected =>
      _items.cast<CanvasItem?>().firstWhere((i) => i!.isSelected, orElse: () => null);

  int get _selectedIndex => _items.indexWhere((i) => i.isSelected);

  @override
  void initState() {
    super.initState();
    _loadClothes();
  }

  Future<void> _loadClothes() async {
    try {
      final r = await _clothService.getMyClothes();
      setState(() {
        _clothes = r.items;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _select(int index) {
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        _items[i].isSelected = (i == index);
      }
      _activePanel = _ToolPanel.none;
    });
  }

  void _deselect() {
    setState(() {
      for (final item in _items) { item.isSelected = false; }
      _activePanel = _ToolPanel.none;
    });
  }

  void _addClothes(List<Cloth> selected) {
    final sz = _canvasSize();
    setState(() {
      for (final cloth in selected) {
        for (final item in _items) { item.isSelected = false; }
        _items.add(CanvasItem(
          cloth: cloth,
          position: Offset(sz.width / 2 - 60, sz.height / 2 - 80),
          isSelected: true,
        ));
      }
      _activePanel = _ToolPanel.none;
    });
  }

  void _removeSelected() {
    setState(() {
      _items.removeWhere((i) => i.isSelected);
      _activePanel = _ToolPanel.none;
    });
  }

  void _bringToFront() {
    final idx = _selectedIndex;
    if (idx < 0 || idx == _items.length - 1) return;
    setState(() {
      final item = _items.removeAt(idx);
      _items.add(item);
    });
  }

  void _sendToBack() {
    final idx = _selectedIndex;
    if (idx <= 0) return;
    setState(() {
      final item = _items.removeAt(idx);
      _items.insert(0, item);
    });
  }

  void _flipH() {
    final s = _selected;
    if (s == null) return;
    setState(() => s.flipH = !s.flipH);
  }

  void _flipV() {
    final s = _selected;
    if (s == null) return;
    setState(() => s.flipV = !s.flipV);
  }

  void _quickRotate(double degrees) {
    final s = _selected;
    if (s == null) return;
    setState(() {
      s.rotation = (s.rotation + degrees * math.pi / 180)
          .clamp(-math.pi, math.pi);
    });
  }

  Size _canvasSize() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size ?? const Size(400, 500);
  }

  Future<void> _goToSave() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Добавьте хотя бы одну вещь')));
      return;
    }
    setState(() => _isCapturing = true);
    try {
      
      for (final item in _items) { item.isSelected = false; }
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 80));

      Uint8List? pngBytes;
      try {
        final boundary =
            _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final bd = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      } catch (_) {}

      String? thumbnailUrl;
      if (pngBytes != null) {
        final r = await _apiService.uploadBytes(
          '/upload/uploadCanvas',
          pngBytes,
          'canvas_${DateTime.now().millisecondsSinceEpoch}.png',
          fields: {},
        );
        thumbnailUrl = r['imageUrl'] as String?;
      }

      final clothesIds = _items.map((i) => i.cloth.id).toSet().toList();

      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OutfitSavePage(
            thumbnailUrl: thumbnailUrl,
            clothesIds: clothesIds,
          ),
        ),
      );
      if (saved == true && mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickBgColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(initial: _bgColor),
    );
    if (color != null) setState(() => _bgColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelected = _selected != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Редактор образа'),
        actions: [
          if (_isCapturing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Далее',
              onPressed: _goToSave,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                
                Expanded(
                  child: GestureDetector(
                    onTap: _deselect,
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: Container(
                        color: _bgColor,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            
                            if (_bgColor == Colors.white)
                              CustomPaint(
                                painter: _GridPainter(),
                                child: Container(),
                              ),
                            ..._items.asMap().entries.map(
                                  (e) => _buildItem(e.key, e.value),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                
                _buildBottomBar(hasSelected),
              ],
            ),
    );
  }

  

  Widget _buildItem(int index, CanvasItem item) {
    const w = 120.0;
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () => _select(index),
        onScaleStart: (d) {
          _gestureStartFocal = d.localFocalPoint;
          _gestureStartScale = item.scale;
          _gestureStartRotation = item.rotation;
          _gestureStartPosition = item.position;
          _select(index);
        },
        onScaleUpdate: (d) {
          setState(() {
            if (_gestureStartPosition != null && _gestureStartFocal != null) {
              item.position = _gestureStartPosition! + (d.localFocalPoint - _gestureStartFocal!);
            }
            if (_gestureStartScale != null) {
              item.scale = (_gestureStartScale! * d.scale).clamp(0.2, 5.0);
            }
            if (_gestureStartRotation != null && d.rotation != 0) {
              item.rotation = _gestureStartRotation! + d.rotation;
            }
          });
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: Transform(
            transform: Matrix4.diagonal3Values(
              item.flipH ? -item.scale : item.scale,
              item.flipV ? -item.scale : item.scale,
              1,
            ),
            alignment: Alignment.center,
            child: Container(
              decoration: item.isSelected
                  ? BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: CachedNetworkImage(
                imageUrl: item.cloth.processedImageUrl ?? item.cloth.imageUrl,
                width: w,
                fit: BoxFit.contain,
                placeholder: (ctx, url) => const SizedBox(
                    width: w, height: w, child: Center(child: CircularProgressIndicator())),
                errorWidget: (ctx, url, err) =>
                    Image.network(item.cloth.imageUrl, width: w, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  Widget _buildBottomBar(bool hasSelected) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          if (_activePanel == _ToolPanel.scale && _selected != null)
            _ScalePanel(
              value: _selected!.scale,
              onChanged: (v) => setState(() => _selected!.scale = v),
            ),
          if (_activePanel == _ToolPanel.rotate && _selected != null)
            _RotatePanel(
              value: _selected!.rotation,
              onChanged: (v) => setState(() => _selected!.rotation = v),
              onQuick: _quickRotate,
            ),

          
          SizedBox(
            height: 60,
            child: Row(
              children: [
                
                _BarBtn(
                  icon: Icons.add_circle_outline,
                  label: 'Добавить',
                  onTap: () async {
                    final picked = await showModalBottomSheet<List<Cloth>>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => _ClothPickerSheet(clothes: _clothes),
                    );
                    if (picked != null && picked.isNotEmpty) _addClothes(picked);
                  },
                ),

                const VerticalDivider(width: 1, indent: 12, endIndent: 12),

                if (hasSelected) ...[
                  _BarBtn(
                    icon: Icons.flip_to_front,
                    label: 'Вперёд',
                    onTap: _bringToFront,
                  ),
                  _BarBtn(
                    icon: Icons.flip_to_back,
                    label: 'Назад',
                    onTap: _sendToBack,
                  ),
                  _BarBtn(
                    icon: Icons.flip,
                    label: 'Зеркало\nH',
                    onTap: _flipH,
                  ),
                  _BarBtn(
                    icon: Icons.flip,
                    label: 'Зеркало\nV',
                    extra: true,
                    onTap: _flipV,
                  ),
                  _BarBtn(
                    icon: Icons.zoom_in,
                    label: 'Размер',
                    active: _activePanel == _ToolPanel.scale,
                    onTap: () => setState(() => _activePanel =
                        _activePanel == _ToolPanel.scale ? _ToolPanel.none : _ToolPanel.scale),
                  ),
                  _BarBtn(
                    icon: Icons.rotate_right,
                    label: 'Поворот',
                    active: _activePanel == _ToolPanel.rotate,
                    onTap: () => setState(() => _activePanel =
                        _activePanel == _ToolPanel.rotate ? _ToolPanel.none : _ToolPanel.rotate),
                  ),
                  _BarBtn(
                    icon: Icons.delete_outline,
                    label: 'Удалить',
                    color: Colors.red,
                    onTap: _removeSelected,
                  ),
                ],

                const Spacer(),
                const VerticalDivider(width: 1, indent: 12, endIndent: 12),

                
                _BarBtn(
                  icon: Icons.palette_outlined,
                  label: 'Фон',
                  onTap: _pickBgColor,
                  colorSwatch: _bgColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _ScalePanel extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ScalePanel({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.zoom_out, size: 20),
          Expanded(
            child: Slider(
              value: value.clamp(0.2, 5.0),
              min: 0.2,
              max: 5.0,
              divisions: 48,
              label: '×${value.toStringAsFixed(1)}',
              onChanged: onChanged,
            ),
          ),
          const Icon(Icons.zoom_in, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text('×${value.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}



class _RotatePanel extends StatelessWidget {
  final double value; 
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onQuick;

  const _RotatePanel(
      {required this.value, required this.onChanged, required this.onQuick});

  @override
  Widget build(BuildContext context) {
    final deg = value * 180 / math.pi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.rotate_left),
            tooltip: '-45°',
            onPressed: () => onQuick(-45),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(-math.pi, math.pi),
              min: -math.pi,
              max: math.pi,
              divisions: 72,
              label: '${deg.round()}°',
              onChanged: onChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: '+45°',
            onPressed: () => onQuick(45),
          ),
          SizedBox(
            width: 44,
            child: Text('${deg.round()}°',
                style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}



enum _ToolPanel { none, scale, rotate }

class _BarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool extra; 
  final Color? color;
  final Color? colorSwatch;

  const _BarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.extra = false,
    this.color,
    this.colorSwatch,
  });

  @override
  Widget build(BuildContext context) {
    final c = active
        ? Theme.of(context).colorScheme.primary
        : color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: active
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Transform.rotate(
                  angle: extra ? math.pi / 2 : 0,
                  child: Icon(icon, size: 22, color: c),
                ),
                if (colorSwatch != null)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorSwatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 9, color: c, height: 1.1),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}



class _ClothPickerSheet extends StatefulWidget {
  final List<Cloth> clothes;

  const _ClothPickerSheet({required this.clothes});

  @override
  State<_ClothPickerSheet> createState() => _ClothPickerSheetState();
}

class _ClothPickerSheetState extends State<_ClothPickerSheet> {
  final Set<int> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text('Выберите вещи',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                    onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          final picked = widget.clothes
                              .where((c) => _selectedIds.contains(c.id))
                              .toList();
                          Navigator.pop(context, picked);
                        },
                  icon: const Icon(Icons.check),
                  label: Text(_selectedIds.isEmpty
                      ? 'Добавить'
                      : 'Добавить (${_selectedIds.length})'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          widget.clothes.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Text('Гардероб пуст',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: widget.clothes.length,
                    itemBuilder: (ctx, i) {
                      final cloth = widget.clothes[i];
                      final selected = _selectedIds.contains(cloth.id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedIds.remove(cloth.id);
                          } else {
                            _selectedIds.add(cloth.id);
                          }
                        }),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[300]!,
                                  width: selected ? 2.5 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: CachedNetworkImage(
                                  imageUrl: cloth.processedImageUrl ?? cloth.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) =>
                                      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (c, u, e) =>
                                      Image.network(cloth.imageUrl, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            if (selected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(9),
                                      bottomRight: Radius.circular(9)),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  cloth.name ?? cloth.category ?? cloth.typeLabel,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}



class _ColorPickerDialog extends StatefulWidget {
  final Color initial;

  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _current;

  static const _presets = [
    Colors.white,
    Color(0xFFF5F5F0), 
    Color(0xFFE8E8E8), 
    Color(0xFFD4D4BF), 
    Color(0xFFF0E6D3), 
    Color(0xFFDDE8DD), 
    Color(0xFFD6E4F0), 
    Color(0xFFF5D5D5), 
    Color(0xFFE8D5F0), 
    Color(0xFF2B2B2B), 
    Color(0xFF1A1A2E), 
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Цвет фона'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _presets.map((c) {
          final isSelected = _current.toARGB32() == c.toARGB32();
          return GestureDetector(
            onTap: () => setState(() => _current = c),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[400]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, _current),
            child: const Text('Выбрать')),
      ],
    );
  }
}



class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
