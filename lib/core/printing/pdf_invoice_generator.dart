import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/invoices/domain/entities/invoice.dart';
import '../../features/settings/domain/entities/settings.dart';
import 'package:intl/intl.dart';

class PdfInvoiceGenerator {
  static Future<void> printInvoice(Invoice invoice, Settings settings) async {
    final pdf = pw.Document();
    
    // Premium Color Palette
    const primaryColor = PdfColor.fromInt(0xFF1E3A8A); // Deep Blue
    const secondaryColor = PdfColor.fromInt(0xFF3B82F6); // Lighter Blue
    const accentColor = PdfColor.fromInt(0xFFF3F4F6); // Light Gray Background
    const textColor = PdfColor.fromInt(0xFF1F2937); // Dark Gray
    const lightText = PdfColor.fromInt(0xFF6B7280); // Gray

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(settings, primaryColor, secondaryColor),
            pw.SizedBox(height: 30),
            _buildInvoiceDetails(invoice, settings, textColor, lightText, primaryColor),
            pw.SizedBox(height: 30),
            _buildItemsTable(invoice, settings, primaryColor, accentColor, textColor),
            pw.SizedBox(height: 20),
            _buildTotalsSection(invoice, settings, primaryColor, textColor),
            pw.SizedBox(height: 50),
            _buildFooter(settings, lightText),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.id}.pdf',
    );
  }

  static pw.Widget _buildHeader(Settings settings, PdfColor primary, PdfColor secondary) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(settings.businessName.toUpperCase(), style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: primary)),
            pw.SizedBox(height: 6),
            pw.Text(settings.businessAddress, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text('Phone: ${settings.phoneNumber}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            if (settings.gstNumber != null && settings.gstNumber!.isNotEmpty)
              pw.Text('GSTIN: ${settings.gstNumber}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: secondary,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 2)),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(Invoice invoice, Settings settings, PdfColor text, PdfColor lightText, PdfColor primary) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Billed To', style: pw.TextStyle(fontSize: 10, color: lightText, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.customer?.name ?? 'Walk-in Customer', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: text)),
              if (invoice.customer?.email != null) pw.Text(invoice.customer!.email!, style: pw.TextStyle(fontSize: 10, color: text)),
              if (invoice.customer?.phone != null) pw.Text(invoice.customer!.phone!, style: pw.TextStyle(fontSize: 10, color: text)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildDetailRow('Invoice No:', '${settings.invoicePrefix}${invoice.id}', lightText, text),
              _buildDetailRow('Date:', invoice.createdAt != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(invoice.createdAt!)) : 'N/A', lightText, text),
              _buildDetailRow('Payment Method:', invoice.paymentMethod ?? 'CASH', lightText, text),
              _buildDetailRow('Status:', invoice.status ?? 'UNPAID', lightText, invoice.status == 'PAID' ? PdfColors.green : PdfColors.orange),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDetailRow(String label, String value, PdfColor labelColor, PdfColor valueColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: labelColor, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 16),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, color: valueColor, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice, Settings settings, PdfColor primary, PdfColor accent, PdfColor text) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
          ),
          children: [
            _buildTableHeader('Item Description'),
            _buildTableHeader('Qty', align: pw.TextAlign.right),
            _buildTableHeader('Unit Price', align: pw.TextAlign.right),
            _buildTableHeader('Tax', align: pw.TextAlign.right),
            _buildTableHeader('Amount', align: pw.TextAlign.right),
          ],
        ),
        ...List.generate(invoice.items.length, (index) {
          final item = invoice.items[index];
          final isEven = index % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : accent,
              border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            children: [
              _buildTableCell(item.productName ?? 'Product', text),
              _buildTableCell(item.quantity.toString(), text, align: pw.TextAlign.right),
              _buildTableCell('${settings.currency}${item.unitPrice?.toStringAsFixed(2)}', text, align: pw.TextAlign.right),
              _buildTableCell('${item.taxPercentage}%', text, align: pw.TextAlign.right),
              _buildTableCell('${settings.currency}${item.lineTotal?.toStringAsFixed(2)}', text, align: pw.TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildTableCell(String text, PdfColor color, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(color: color, fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static pw.Widget _buildTotalsSection(Invoice invoice, Settings settings, PdfColor primary, PdfColor text) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: primary, width: 2),
        ),
        padding: const pw.EdgeInsets.all(16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildTotalRow('Subtotal', '${settings.currency}${invoice.subtotal.toStringAsFixed(2)}', text),
            if (invoice.discountAmount > 0)
              _buildTotalRow('Discount (${invoice.discountPercentage}%)', '-${settings.currency}${invoice.discountAmount.toStringAsFixed(2)}', PdfColors.red),
            _buildTotalRow('Tax', '${settings.currency}${invoice.taxTotal.toStringAsFixed(2)}', text),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            _buildTotalRow('Grand Total', '${settings.currency}${invoice.grandTotal.toStringAsFixed(2)}', primary, isBold: true, size: 16),
            pw.SizedBox(height: 8),
            _buildTotalRow('Amount Paid', '${settings.currency}${invoice.amountPaid.toStringAsFixed(2)}', PdfColors.green),
            _buildTotalRow('Balance Due', '${settings.currency}${invoice.balanceDue.toStringAsFixed(2)}', invoice.balanceDue > 0 ? PdfColors.red : PdfColors.green, isBold: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, PdfColor color, {bool isBold = false, double size = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: size, color: color, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: size, color: color, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(Settings settings, PdfColor lightText) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 12),
        pw.Text(settings.invoiceFooter, style: pw.TextStyle(fontSize: 10, color: lightText, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        pw.Text('Generated by Billway', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ],
    );
  }
}
