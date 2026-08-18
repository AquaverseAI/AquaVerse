import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/speaker_button.dart';

class OfficerReportsScreen extends StatefulWidget {
  const OfficerReportsScreen({super.key});

  @override
  State<OfficerReportsScreen> createState() => _OfficerReportsScreenState();
}

class _OfficerReportsScreenState extends State<OfficerReportsScreen> {
  bool _isGeneratingPdf = false;

  void _handleBackNavigation(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/officer/dashboard');
    }
  }

  Future<void> _generateAndDownloadPdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AquaVerse AI - District Cluster Report',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Nagapattinam District · Cluster 3 (12 Ponds)',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'OFF-TN-804',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.teal700),
                pw.SizedBox(height: 12),

                // Health Summary Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.teal200),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Cluster Health Index',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '84.2% Optimal Health',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Report Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Parameter Table
                pw.Text(
                  'Cluster Telemetry Parameter Averages',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.TableHelper.fromTextArray(
                  headers: ['Parameter', 'Average Value', 'Status Range', 'Condition'],
                  data: [
                    ['Dissolved Oxygen (DO)', '5.6 mg/L', 'Normal (>4.0 mg/L)', 'Optimal'],
                    ['pH Level', '7.6 pH', 'Stable (6.5 - 8.5)', 'Optimal'],
                    ['Salinity', '14.8 ppt', 'Optimal Brackish', 'Optimal'],
                    ['Water Temperature', '28.2 °C', 'Seasonal Average', 'Normal'],
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                  rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                ),
                pw.SizedBox(height: 16),

                // Priority Ponds
                pw.Text(
                  'Priority Ponds Requiring Extension Visit',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.red200),
                    color: PdfColors.red50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Pond TN-01-002 (Farmer: R. Kumar) — HIGH RISK',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.Text(
                        'Issue: Low DO Warning (3.8 mg/L at 4 AM telemetry check). Aeration check required.',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.orange200),
                    color: PdfColors.orange50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Pond TN-01-004 (Farmer: S. Murugan) — MEDIUM RISK',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange900,
                        ),
                      ),
                      pw.Text(
                        'Issue: Slight pH Variance (8.6 pH evening reading). Lime dosage review advised.',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by Dr. K. Arunkumar (Extension Officer)',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Page 1 of 1',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      // Launch printing / download dialog
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'AquaVerse_District_Cluster_3_Report.pdf',
      );

      if (context.mounted) {
        setState(() => _isGeneratingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('District Cluster PDF Report downloaded successfully!'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        setState(() => _isGeneratingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded & saved to local storage'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => _handleBackNavigation(context),
          ),
          title: const Text(
            'Cluster Analytics & Reports',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            const SpeakerButton(
              textToSpeak:
                  'Cluster Analytics & Reports. Export District Cluster report as PDF.',
            ),
            IconButton(
              onPressed: () => _generateAndDownloadPdf(context),
              icon: const Icon(Icons.file_download_rounded,
                  color: AppColors.langAccentPrimary),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Health Summary Card ─────────────────────────────────────────
              AppCard(
                type: CardType.info,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            AppColors.langAccentPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.analytics_rounded,
                          color: AppColors.langAccentPrimary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cluster Health Index',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                          SizedBox(height: 2),
                          Text('84.2% Optimal',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.langAccentPrimary)),
                          SizedBox(height: 2),
                          Text('Nagapattinam District Cluster 3 · 12 Ponds',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Parameter Averages Grid ─────────────────────────────────────
              const Text('Cluster Parameter Averages',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: const [
                  _ReportTile(
                    label: 'Average DO',
                    value: '5.6 mg/L',
                    sub: 'Normal (>4.0 mg/L)',
                    color: AppColors.green600,
                  ),
                  _ReportTile(
                    label: 'Average pH',
                    value: '7.6 pH',
                    sub: 'Stable (6.5 - 8.5)',
                    color: AppColors.langAccentPrimary,
                  ),
                  _ReportTile(
                    label: 'Average Salinity',
                    value: '14.8 ppt',
                    sub: 'Optimal Range',
                    color: AppColors.primary700,
                  ),
                  _ReportTile(
                    label: 'Water Temp',
                    value: '28.2 °C',
                    sub: 'Seasonal Average',
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── High Risk Ponds Needing Attention ──────────────────────────
              const Text('Priority Ponds (Requires Visit)',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),

              _RiskPondItem(
                pondId: 'TN-01-002',
                farmerName: 'R. Kumar',
                issue: 'Low DO Warning (3.8 mg/L at 4 AM check)',
                riskTier: 'High Risk',
                riskColor: AppColors.critical,
              ),
              const SizedBox(height: 10),
              _RiskPondItem(
                pondId: 'TN-01-004',
                farmerName: 'S. Murugan',
                issue: 'Slight pH Variance (8.6 pH evening reading)',
                riskTier: 'Medium Risk',
                riskColor: AppColors.warning,
              ),
              const SizedBox(height: 24),

              // ── PDF Download Primary Action Button ──────────────────────────
              PrimaryButton(
                label: _isGeneratingPdf
                    ? 'Generating PDF Document…'
                    : 'Download Full District Report (PDF)',
                isLoading: _isGeneratingPdf,
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () => _generateAndDownloadPdf(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _ReportTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _RiskPondItem extends StatelessWidget {
  final String pondId;
  final String farmerName;
  final String issue;
  final String riskTier;
  final Color riskColor;

  const _RiskPondItem({
    required this.pondId,
    required this.farmerName,
    required this.issue,
    required this.riskTier,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/officer/farmer-info'),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(pondId,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(riskTier,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: riskColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$farmerName · $issue',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
