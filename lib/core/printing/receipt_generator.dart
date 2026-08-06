import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../features/invoices/domain/entities/invoice.dart';
import '../../features/settings/domain/entities/settings.dart';
import 'package:intl/intl.dart';

class ReceiptGenerator {
  static Future<List<int>> generateReceipt(Invoice invoice, Settings settings, {PaperSize paperSize = PaperSize.mm80}) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(settings.businessName, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(settings.businessAddress, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Phone: ${settings.phoneNumber}', styles: const PosStyles(align: PosAlign.center));
    if (settings.gstNumber != null && settings.gstNumber!.isNotEmpty) {
      bytes += generator.text('GST: ${settings.gstNumber}', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(1);
    
    // Invoice Details
    bytes += generator.text('INVOICE', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('No: ${settings.invoicePrefix}${invoice.id}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Date: ${invoice.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(invoice.createdAt!)) : 'N/A'}', styles: const PosStyles(align: PosAlign.left));
    if (invoice.customer != null) {
      bytes += generator.text('Customer: ${invoice.customer!.name}', styles: const PosStyles(align: PosAlign.left));
    }
    bytes += generator.feed(1);

    // Items Header
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr();

    // Items
    for (var item in invoice.items) {
      bytes += generator.row([
        PosColumn(text: item.productName ?? 'Item', width: 6),
        PosColumn(text: item.quantity.toString(), width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: '${item.lineTotal?.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();

    // Totals
    bytes += _buildTotalRow(generator, 'Subtotal', invoice.subtotal.toStringAsFixed(2));
    if (invoice.discountAmount > 0) {
      bytes += _buildTotalRow(generator, 'Discount', '-${invoice.discountAmount.toStringAsFixed(2)}');
    }
    bytes += _buildTotalRow(generator, 'Tax', invoice.taxTotal.toStringAsFixed(2));
    bytes += generator.hr();
    bytes += _buildTotalRow(generator, 'Grand Total', '${settings.currency}${invoice.grandTotal.toStringAsFixed(2)}', isBold: true);
    bytes += generator.feed(1);

    bytes += _buildTotalRow(generator, 'Paid', '${settings.currency}${invoice.amountPaid.toStringAsFixed(2)}');
    bytes += _buildTotalRow(generator, 'Balance', '${settings.currency}${invoice.balanceDue.toStringAsFixed(2)}');
    
    // Footer
    bytes += generator.feed(1);
    bytes += generator.text(settings.invoiceFooter, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  static List<int> _buildTotalRow(Generator generator, String label, String value, {bool isBold = false}) {
    return generator.row([
      PosColumn(text: label, width: 6, styles: PosStyles(bold: isBold)),
      PosColumn(text: value, width: 6, styles: PosStyles(bold: isBold, align: PosAlign.right)),
    ]);
  }
}
