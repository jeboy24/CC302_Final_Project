import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0D0B14);
  static const card = Color(0xFF191624);
  static const tile = Color(0xFF242032);
  static const accent = Color(0xFFC3A6FF);
  static const iconBg = Color(0xFF493A68);
  static const muted = Color(0xFFB5AEC5);
  static const border = Color(0xFF332D43);
}

const watchStatuses = [
  'Plan to Watch',
  'Currently Watching',
  'Completed',
  'Dropped',
];

const readStatuses = [
  'Plan to Read',
  'Currently Reading',
  'Completed',
  'Dropped',
];

const allStatuses = [
  'Plan to Watch',
  'Currently Watching',
  'Completed',
  'Dropped',
  'Plan to Read',
  'Currently Reading',
];

List<String> statusesFor(String type) =>
    type == 'Manga' ? readStatuses : watchStatuses;

String defaultStatus(String type) =>
    type == 'Manga' ? 'Plan to Read' : 'Plan to Watch';

Color statusColor(String s) {
  switch (s) {
    case 'Currently Watching':
    case 'Currently Reading':
      return const Color(0xFF6EE7A0);
    case 'Completed':
    case 'Completed Reading':
      return const Color(0xFFFFD166);
    case 'Dropped':
      return const Color(0xFFFF8A8A);
    default:
      return AppColors.muted;
  }
}

IconData typeIcon(String type) {
  switch (type) {
    case 'Manga':
      return Icons.menu_book_outlined;
    case 'Movie':
      return Icons.movie_outlined;
    default:
      return Icons.tv_outlined;
  }
}