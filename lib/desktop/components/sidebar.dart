import 'package:flutter/material.dart';
import '../../main.dart'; // Import pour la palette Sp

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232, // --sw: 232px
      decoration: BoxDecoration(
        color: Sp.bg1,
        border: Border(right: BorderSide(color: Sp.bd)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 35), // Espace draggable
          
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Sp.ac, borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 9),
                RichText(
                  text: const TextSpan(
                    text: 'Askaria',
                    style: TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3),
                    children: [
                      TextSpan(text: '.', style: TextStyle(color: Sp.ac)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SidebarItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemSelected(0),
                ),
                _SidebarItem(
                  icon: Icons.search_rounded,
                  label: 'Rechercher',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemSelected(1),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            child: Divider(color: Sp.bd, height: 1),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 4, 10, 5),
                  child: Text('BIBLIOTHÈQUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Sp.t4, letterSpacing: 1.0)),
                ),
                _SidebarItem(
                  icon: Icons.library_music_rounded,
                  label: 'Titres',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemSelected(2),
                ),
                _SidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Paramètres',
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemSelected(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    VoidCallback? onEnter = (_) => setState(() => _hover = true);
    VoidCallback? onExit = (_) => setState(() => _hover = false);
    
    final color = widget.isSelected ? Sp.t1 : (_hover ? Sp.t1 : Sp.t3);
    final bgColor = widget.isSelected ? Colors.white.withOpacity(0.08) : (_hover ? Colors.white.withOpacity(0.04) : Colors.transparent);

    return MouseRegion(
      onEnter: onEnter, onExit: onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(7)),
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              if (widget.isSelected)
                Positioned(
                  left: -10,
                  child: Container(
                    width: 2.5, height: 15,
                    decoration: const BoxDecoration(
                      color: Sp.ac,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(2)),
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(widget.icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
