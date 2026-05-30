import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';

class ComponentsTab extends StatelessWidget {
  final ThemeTokens tk;
  final ThemeEditorNotifier n;

  const ComponentsTab({
    super.key,
    required this.tk,
    required this.n,
  });

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.tryParse(h, radix: 16) ?? 0xFFAAAAAA);
  }

  Widget _sec(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: RevoTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: RevoTheme.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Container(height: 1, width: 40, color: RevoTheme.cardBorder),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> opts, ValueChanged<String?> cb) {
    final safe = opts.contains(value) ? value : opts.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey(safe),
        initialValue: safe,
        onChanged: cb,
        isDense: true,
        style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.inter(fontSize: 12)))).toList(),
      ),
    );
  }

  Widget _componentsPreviewGrid() {
    final pri = _hex(tk.primaryColor);
    final bg = _hex(tk.backgroundColor);
    final card = _hex(tk.cardColor);
    final text = _hex(tk.textPrimaryColor);
    final textSec = _hex(tk.textSecondaryColor);
    final rad = BorderRadius.circular(tk.borderRadius);

    Widget styleCard(String title, Widget content) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: rad,
          border: Border.all(color: RevoTheme.cardBorder),
          boxShadow: tk.cardStyle == 'elevated'
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: textSec)),
            const SizedBox(height: 8),
            Center(child: content),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: rad,
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          // 1. Button + Input + Chip
          styleCard('Buttons & Input Fields', Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pri,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: rad),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Button', style: TextStyle(fontSize: 10)),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: pri),
                      foregroundColor: pri,
                      shape: RoundedRectangleBorder(borderRadius: rad),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Outlined', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Themed Input',
                  labelStyle: TextStyle(color: textSec, fontSize: 10),
                  filled: tk.inputStyle == 'filled',
                  fillColor: pri.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                  border: tk.inputStyle == 'outline'
                      ? OutlineInputBorder(borderRadius: rad)
                      : tk.inputStyle == 'underline'
                          ? const UnderlineInputBorder()
                          : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: rad),
                ),
              ),
            ],
          )),

          // 2. Dialog Preview
          styleCard('Dialog (${tk.dialogStyle})', Container(
            width: 200,
            decoration: BoxDecoration(
              color: card,
              borderRadius: rad,
              border: tk.dialogStyle == 'outlined' ? Border.all(color: pri) : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: tk.dialogStyle == 'elevated'
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dialog Header', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
                const SizedBox(height: 4),
                Text('Dialog details and text description.', style: TextStyle(fontSize: 9, color: textSec)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Cancel', style: TextStyle(fontSize: 9, color: pri, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('OK', style: TextStyle(fontSize: 9, color: pri, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )),

          // 3. Drawer & BottomSheet Previews
          styleCard('Drawer (${tk.drawerStyle}) & BottomSheet (${tk.bottomSheetStyle})', Row(
            children: [
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: card,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: tk.drawerStyle == 'floating' ? rad : BorderRadius.zero,
                ),
                child: Column(
                  children: [
                    Container(height: 15, color: pri),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (_) => Row(
                          children: [
                            const SizedBox(width: 4),
                            Icon(Icons.circle, size: 4, color: pri),
                            const SizedBox(width: 4),
                            Container(width: 20, height: 2, color: textSec.withValues(alpha: 0.5)),
                          ],
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 90,
                height: 70,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0, left: 2, right: 2,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          boxShadow: tk.bottomSheetStyle == 'elevated'
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                              : null,
                          border: tk.bottomSheetStyle == 'glass' ? Border.all(color: pri.withValues(alpha: 0.3)) : null,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 3),
                            Container(width: 14, height: 2, color: Colors.grey),
                            const Spacer(),
                            Text('Actions sheet', style: TextStyle(fontSize: 8, color: text)),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),

          // 4. TabBar & NavigationBar Previews
          styleCard('TabBar (${tk.tabBarStyle}) & NavigationBar (${tk.navigationBarStyle})', Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tk.tabBarStyle == 'pill' ? pri : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: tk.tabBarStyle == 'underlined' ? Border(bottom: BorderSide(color: pri, width: 2)) : null,
                    ),
                    child: Text('Active', style: TextStyle(fontSize: 9, color: tk.tabBarStyle == 'pill' ? Colors.white : pri, fontWeight: FontWeight.bold)),
                  ),
                  Text('Inactive', style: TextStyle(fontSize: 9, color: textSec)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 25,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: tk.navigationBarStyle == 'floating' ? rad : BorderRadius.zero,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.home, size: 12, color: pri),
                    Icon(Icons.search, size: 12, color: textSec),
                    Icon(Icons.person, size: 12, color: textSec),
                  ],
                ),
              ),
            ],
          )),

          // 5. ListTile & Table Previews
          styleCard('ListTile (${tk.listTileStyle}) & Table (${tk.tableStyle})', Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: tk.listTileStyle == 'card' ? card : Colors.transparent,
                  borderRadius: rad,
                  border: tk.listTileStyle == 'bordered' ? Border.all(color: Colors.grey.withValues(alpha: 0.3)) : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: pri, child: const Icon(Icons.person, size: 8, color: Colors.white)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ListTile Title', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: text)),
                        Text('Subtitle text', style: TextStyle(fontSize: 7, color: textSec)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 12, color: textSec),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Table(
                border: tk.tableStyle == 'bordered' ? TableBorder.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5) : const TableBorder(),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: pri.withValues(alpha: 0.1)),
                    children: [
                      Padding(padding: const EdgeInsets.all(4), child: Text('Col 1', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: text))),
                      Padding(padding: const EdgeInsets.all(4), child: Text('Col 2', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: text))),
                    ],
                  ),
                  TableRow(
                    decoration: BoxDecoration(color: tk.tableStyle == 'striped' ? Colors.grey.withValues(alpha: 0.05) : Colors.transparent),
                    children: [
                      Padding(padding: const EdgeInsets.all(4), child: Text('Val A', style: const TextStyle(fontSize: 8))),
                      Padding(padding: const EdgeInsets.all(4), child: Text('Val B', style: const TextStyle(fontSize: 8))),
                    ],
                  ),
                ],
              ),
            ],
          )),

          // 6. Stepper & Snackbar Previews
          styleCard('Stepper (${tk.stepperStyle}) & Snackbar (${tk.snackbarStyle})', Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 6, backgroundColor: pri, child: const Text('1', style: TextStyle(fontSize: 6, color: Colors.white))),
                  Container(width: 25, height: 1.5, color: pri),
                  CircleAvatar(radius: 6, backgroundColor: Colors.grey, child: Text('2', style: TextStyle(fontSize: 6, color: textSec))),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: text,
                  borderRadius: tk.snackbarStyle == 'floating' ? rad : BorderRadius.zero,
                  border: tk.snackbarStyle == 'left-accent' ? Border(left: BorderSide(color: pri, width: 3.5)) : null,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('Alert notification text', style: TextStyle(fontSize: 8, color: card))),
                    Text('Undo', style: TextStyle(fontSize: 8, color: pri, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          )),

          // 7. Enterprise Components Previews (DataGrid, Calendar, TreeView, Charts, Timeline, Kanban)
          styleCard('DataGrid (${tk.dataGridStyle}) & Calendar (${tk.calendarStyle})', Column(
            children: [
              // DataGrid
              Container(
                decoration: BoxDecoration(
                  color: card,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      color: pri.withValues(alpha: 0.08),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Text('ID', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: pri)),
                          const Spacer(),
                          Text('Product Name', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: pri)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          const Text('#101', style: TextStyle(fontSize: 7)),
                          const Spacer(),
                          Text('Revo Engine', style: TextStyle(fontSize: 7, color: textSec)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Calendar
              Container(
                width: 140,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tk.calendarStyle == 'card' ? card : Colors.transparent,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: rad,
                ),
                child: Column(
                  children: [
                    Text('May 2026', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: text)),
                    const SizedBox(height: 4),
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(14, (idx) {
                        final isSelected = idx == 10;
                        return Container(
                          alignment: Alignment.center,
                          decoration: isSelected
                              ? BoxDecoration(color: pri, shape: BoxShape.circle)
                              : null,
                          child: Text('${idx + 1}',
                              style: TextStyle(fontSize: 7, color: isSelected ? Colors.white : text)),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          )),

          styleCard('TreeView (${tk.treeViewStyle}) & Charts (${tk.chartsStyle})', Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TreeView
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_open, size: 10, color: pri),
                        const SizedBox(width: 4),
                        Text('root', style: TextStyle(fontSize: 8, color: text)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.keyboard_arrow_right, size: 8, color: textSec),
                          Icon(Icons.insert_drive_file, size: 10, color: textSec),
                          const SizedBox(width: 2),
                          Text('config.json', style: TextStyle(fontSize: 8, color: textSec)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Charts
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: CustomPaint(
                    painter: _MiniChartPainter(color: pri, style: tk.chartsStyle),
                  ),
                ),
              ),
            ],
          )),

          styleCard('Timeline (${tk.timelineStyle}) & Kanban (${tk.kanbanStyle})', Column(
            children: [
              // Timeline
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked, size: 10, color: pri),
                      Container(width: 1, height: 20, color: pri),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step 1 Complete', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: text)),
                      Text('10:45 AM', style: TextStyle(fontSize: 6, color: textSec)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Kanban
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniKanbanColumn(pri, card, text, textSec, 'To Do', rad),
                  _miniKanbanColumn(pri, card, text, textSec, 'Done', rad),
                ],
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _miniKanbanColumn(Color pri, Color card, Color text, Color textSec, String title, BorderRadius rad) {
    return Container(
      width: 75,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: textSec.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: card,
              borderRadius: rad,
              border: tk.kanbanStyle == 'column-outline' ? Border.all(color: pri, width: 0.5) : null,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 30, height: 3, color: pri),
                const SizedBox(height: 3),
                Text('Task Details', style: TextStyle(fontSize: 6, color: textSec)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('Dropdown Styles', Icons.settings_applications),
        const SizedBox(height: 8),
        _dropdown('Button Style', tk.buttonStyle, ['elevated', 'outlined', 'flat', 'tonal'], (v) => n.updateTheme(tk.copyWith(buttonStyle: v))),
        _dropdown('Input Field Style', tk.inputStyle, ['outline', 'filled', 'underline'], (v) => n.updateTheme(tk.copyWith(inputStyle: v))),
        _dropdown('Card Style', tk.cardStyle, ['flat', 'elevated', 'outlined', 'glass'], (v) => n.updateTheme(tk.copyWith(cardStyle: v))),
        _dropdown('AppBar Style', tk.appBarStyle, ['solid', 'transparent', 'gradient', 'glass'], (v) => n.updateTheme(tk.copyWith(appBarStyle: v))),
        _dropdown('Chip Style', tk.chipStyle, ['filled', 'outlined', 'elevated'], (v) => n.updateTheme(tk.copyWith(chipStyle: v))),
        _dropdown('Dialog Style', tk.dialogStyle, ['flat', 'elevated', 'outlined', 'glass'], (v) => n.updateTheme(tk.copyWith(dialogStyle: v))),
        _dropdown('Drawer Style', tk.drawerStyle, ['standard', 'modern', 'floating'], (v) => n.updateTheme(tk.copyWith(drawerStyle: v))),
        _dropdown('BottomSheet Style', tk.bottomSheetStyle, ['flat', 'elevated', 'glass'], (v) => n.updateTheme(tk.copyWith(bottomSheetStyle: v))),
        _dropdown('TabBar Style', tk.tabBarStyle, ['standard', 'pill', 'underlined'], (v) => n.updateTheme(tk.copyWith(tabBarStyle: v))),
        _dropdown('NavigationBar Style', tk.navigationBarStyle, ['standard', 'floating', 'minimal'], (v) => n.updateTheme(tk.copyWith(navigationBarStyle: v))),
        _dropdown('ListTile Style', tk.listTileStyle, ['flat', 'card', 'bordered'], (v) => n.updateTheme(tk.copyWith(listTileStyle: v))),
        _dropdown('Table Style', tk.tableStyle, ['standard', 'striped', 'bordered'], (v) => n.updateTheme(tk.copyWith(tableStyle: v))),
        _dropdown('Stepper Style', tk.stepperStyle, ['standard', 'timeline', 'dots'], (v) => n.updateTheme(tk.copyWith(stepperStyle: v))),
        _dropdown('Snackbar Style', tk.snackbarStyle, ['standard', 'floating', 'left-accent'], (v) => n.updateTheme(tk.copyWith(snackbarStyle: v))),
        
        // 6 new components
        _dropdown('DataGrid Style', tk.dataGridStyle, ['compact', 'striped', 'clean'], (v) => n.updateTheme(tk.copyWith(dataGridStyle: v))),
        _dropdown('Calendar Style', tk.calendarStyle, ['minimalist', 'card', 'inline'], (v) => n.updateTheme(tk.copyWith(calendarStyle: v))),
        _dropdown('TreeView Style', tk.treeViewStyle, ['tree-lines', 'minimalist', 'indent-pill'], (v) => n.updateTheme(tk.copyWith(treeViewStyle: v))),
        _dropdown('Charts Style', tk.chartsStyle, ['solid', 'gradient-line', 'bar-flat'], (v) => n.updateTheme(tk.copyWith(chartsStyle: v))),
        _dropdown('Timeline Style', tk.timelineStyle, ['left-align', 'alternate', 'dot-only'], (v) => n.updateTheme(tk.copyWith(timelineStyle: v))),
        _dropdown('Kanban Style', tk.kanbanStyle, ['board-flat', 'column-outline', 'glass'], (v) => n.updateTheme(tk.copyWith(kanbanStyle: v))),
        
        const SizedBox(height: 16),
        _sec('Component Previews', Icons.remove_red_eye_outlined),
        const SizedBox(height: 10),
        _componentsPreviewGrid(),
      ],
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final Color color;
  final String style;

  _MiniChartPainter({required this.color, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (style == 'gradient-line') {
      final path = Path()
        ..moveTo(0, size.height * 0.8)
        ..quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.5)
        ..quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.2);
      canvas.drawPath(path, paint);
    } else if (style == 'bar-flat') {
      paint.style = PaintingStyle.fill;
      final w = size.width / 5;
      for (int i = 0; i < 4; i++) {
        final x = w * i + w / 2;
        final h = size.height * (0.3 + (i % 3) * 0.2);
        canvas.drawRect(Rect.fromLTWH(x, size.height - h, w - 2, h), paint);
      }
    } else {
      // Solid Line
      canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width * 0.3, size.height * 0.3), paint);
      canvas.drawLine(Offset(size.width * 0.3, size.height * 0.3), Offset(size.width * 0.6, size.height * 0.6), paint);
      canvas.drawLine(Offset(size.width * 0.6, size.height * 0.6), Offset(size.width, size.height * 0.1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
