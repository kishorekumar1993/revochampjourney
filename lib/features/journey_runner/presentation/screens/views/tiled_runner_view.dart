// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class _IT {
//   static const brand = Color(0xFF5B4FCF);
//   static const white = Color(0xFFFFFFFF);
//   static const textDark = Color(0xFF1A1A2E);
//   static const textMid = Color(0xFF6B7280);
//   static const textLight = Color(0xFFB0B4C8);
//   static const border = Color(0xFFE4E6F0);
//   static const success = Color(0xFF22C55E);
//   static const warning = Color(0xFFF59E0B);
//   static const error = Color(0xFFEF4444);
//   static const info = Color(0xFF3B82F6);
// }

// class ApprovalFlowView extends StatefulWidget {
//   const ApprovalFlowView({super.key});

//   @override
//   State<ApprovalFlowView> createState() => _ApprovalFlowViewState();
// }

// class _ApprovalFlowViewState extends State<ApprovalFlowView> {
//   // Mock approval stages
//   final List<ApprovalStage> stages = [
//     ApprovalStage(
//       name: 'Submit Request',
//       status: ApprovalStatus.completed,
//       date: '2025-05-28',
//       comment: 'Request submitted by John',
//     ),
//     ApprovalStage(
//       name: 'Manager Review',
//       status: ApprovalStatus.completed,
//       date: '2025-05-29',
//       comment: 'Approved by Sarah',
//     ),
//     ApprovalStage(
//       name: 'Finance Approval',
//       status: ApprovalStatus.inProgress,
//       date: 'In progress',
//       comment: 'Waiting for budget check',
//     ),
//     ApprovalStage(
//       name: 'Final Sign-off',
//       status: ApprovalStatus.pending,
//       date: 'Pending',
//       comment: '',
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FC),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.all(20),
//                 children: [
//                   _buildTimeline(stages),
//                   const SizedBox(height: 24),
//                   _buildActionButtons(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: _IT.white,
//         border: Border(bottom: BorderSide(color: _IT.border)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.assignment_turned_in, color: _IT.brand, size: 28),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Purchase Order #PO-12345',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'Total: \$12,450.00',
//                 style: GoogleFonts.poppins(color: _IT.textMid),
//               ),
//             ],
//           ),
//           const Spacer(),
//           _buildStatusChip('In Progress', _IT.info),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeline(List<ApprovalStage> stages) {
//     return Container(
//       decoration: BoxDecoration(
//         color: _IT.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: _IT.border),
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: List.generate(stages.length, (index) {
//           final stage = stages[index];
//           final isLast = index == stages.length - 1;
//           return Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildTimelineNode(stage.status, isLast),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         stage.name,
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         stage.date,
//                         style: GoogleFonts.poppins(
//                           fontSize: 12,
//                           color: _IT.textLight,
//                         ),
//                       ),
//                       if (stage.comment.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8),
//                           child: Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: _IT.border,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               stage.comment,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 13,
//                                 color: _IT.textMid,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildTimelineNode(ApprovalStatus status, bool isLast) {
//     Color color;
//     IconData icon;
//     switch (status) {
//       case ApprovalStatus.completed:
//         color = _IT.success;
//         icon = Icons.check_circle;
//         break;
//       case ApprovalStatus.inProgress:
//         color = _IT.info;
//         icon = Icons.radio_button_checked;
//         break;
//       default:
//         color = _IT.border;
//         icon = Icons.radio_button_unchecked;
//     }
//     return Column(
//       children: [
//         Container(
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//           child: Icon(icon, size: 18, color: _IT.white),
//         ),
//         if (!isLast)
//           Container(
//             width: 2,
//             height: 60,
//             color: status == ApprovalStatus.completed
//                 ? _IT.success
//                 : _IT.border,
//           ),
//       ],
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(
//             onPressed: () {},
//             style: OutlinedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               side: const BorderSide(color: _IT.error),
//               foregroundColor: _IT.error,
//             ),
//             child: const Text('Reject'),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: ElevatedButton(
//             onPressed: () {},
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _IT.success,
//               padding: const EdgeInsets.symmetric(vertical: 14),
//             ),
//             child: const Text('Approve'),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusChip(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withValues(alpha: 0.3)),
//       ),
//       child: Text(
//         label,
//         style: GoogleFonts.poppins(
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//           color: color,
//         ),
//       ),
//     );
//   }
// }

// enum ApprovalStatus { pending, inProgress, completed }

// class ApprovalStage {
//   final String name;
//   final ApprovalStatus status;
//   final String date;
//   final String comment;
//   ApprovalStage({
//     required this.name,
//     required this.status,
//     required this.date,
//     required this.comment,
//   });
// }
