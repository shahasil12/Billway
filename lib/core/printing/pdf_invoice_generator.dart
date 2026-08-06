import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/invoices/domain/entities/invoice.dart';
import '../../features/settings/domain/entities/settings.dart';
import 'package:intl/intl.dart';

class PdfInvoiceGenerator {
  static Future<void> printInvoice(Invoice invoice, Settings settings) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(settings),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice, settings),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice, settings),
            pw.SizedBox(height: 20),
            _buildTotals(invoice, settings),
            pw.SizedBox(height: 40),
            _buildFooter(settings),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.id}.pdf',
    );
  }

  static pw.Widget _buildHeader(Settings settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(settings.businessName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 4),
        pw.Text(settings.businessAddress, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.Text('Phone: ${settings.phoneNumber}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        if (settings.gstNumber != null && settings.gstNumber!.isNotEmpty)
          pw.Text('GST: ${settings.gstNumber}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _buildInvoiceInfo(Invoice invoice, Settings settings) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.customer?.name ?? 'Unknown Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (invoice.customer?.email != null) pw.Text(invoice.customer!.email!),
              if (invoice.customer?.phone != null) pw.Text(invoice.customer!.phone!),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 4),
              pw.Text('Invoice No: ${settings.invoicePrefix}${invoice.id}'),
              pw.Text('Date: ${invoice.createdAt != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(invoice.createdAt!)) : 'N/A'}'),
              pw.Text('Status: ${invoice.status}', style: pw.TextStyle(color: invoice.status == 'PAID' ? PdfColors.green : PdfColors.orange)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice, Settings settings) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tax', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),
        ...invoice.items.map((item) {
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.productName ?? 'Product')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.quantity.toString(), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${settings.currency}${item.unitPrice?.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.taxPercentage}%', textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${settings.currency}${item.lineTotal?.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTotals(Invoice invoice, Settings settings) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildTotalRow('Subtotal:', '${settings.currency}${invoice.subtotal.toStringAsFixed(2)}'),
            if (invoice.discountAmount > 0)
              _buildTotalRow('Discount (${invoice.discountPercentage}%):', '-${settings.currency}${invoice.discountAmount.toStringAsFixed(2)}', color: PdfColors.red),
            _buildTotalRow('Tax Total:', '${settings.currency}${invoice.taxTotal.toStringAsFixed(2)}'),
            pw.Divider(),
            _buildTotalRow('Grand Total:', '${settings.currency}${invoice.grandTotal.toStringAsFixed(2)}', isBold: true, size: 16, color: PdfColors.blue800),
            pw.SizedBox(height: 8),
            _buildTotalRow('Amount Paid:', '${settings.currency}${invoice.amountPaid.toStringAsFixed(2)}', color: PdfColors.green),
            _buildTotalRow('Balance Due:', '${settings.currency}${invoice.balanceDue.toStringAsFixed(2)}', isBold: true, color: invoice.balanceDue > 0 ? PdfColors.red : PdfColors.green),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false, double size = 12, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: size, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: size, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(Settings settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(settings.invoiceFooter, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
      ],
    );
  }
}
