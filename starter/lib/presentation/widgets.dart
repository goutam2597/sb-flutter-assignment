import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: Spacing.lg),
          child,
        ],
      ),
    ),
  );
}

class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String title, message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: Spacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    ),
  );
}

class CostBreakdownRow extends StatelessWidget {
  const CostBreakdownRow({
    super.key,
    required this.row,
    required this.currency,
  });
  final CostRow row;
  final String currency;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.cell_tower_outlined),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.provider,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('${row.messageCount} messages'),
            ],
          ),
        ),
        Text(
          row.totalCost.format(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class SendSmsForm extends StatefulWidget {
  const SendSmsForm({
    super.key,
    required this.sending,
    required this.onSend,
    this.retryAfterSeconds = 0,
  });
  final bool sending;
  final int retryAfterSeconds;
  final Future<bool> Function(String, String) onSend;
  @override
  State<SendSmsForm> createState() => _SendSmsFormState();
}

class _SendSmsFormState extends State<SendSmsForm> {
  final phone = TextEditingController(), body = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    phone.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      children: [
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Recipient',
            hintText: '+4915112345678',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (v) => RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v ?? '')
              ? null
              : 'Use international E.164 format',
        ),
        const SizedBox(height: Spacing.md),
        TextFormField(
          controller: body,
          maxLength: 320,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 72),
              child: Icon(Icons.message_outlined),
            ),
          ),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a message' : null,
        ),
        const SizedBox(height: Spacing.xs),
        Semantics(
          label: widget.sending
              ? 'Sending message'
              : widget.retryAfterSeconds > 0
              ? 'Send available in ${widget.retryAfterSeconds} seconds'
              : 'Send SMS',
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.sending || widget.retryAfterSeconds > 0
                  ? null
                  : () async {
                      if (!(form.currentState?.validate() ?? false)) return;
                      final ok = await widget.onSend(phone.text, body.text);
                      if (ok && mounted) {
                        phone.clear();
                        body.clear();
                      }
                    },
              icon: widget.sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                widget.sending
                    ? 'Submitting…'
                    : widget.retryAfterSeconds > 0
                    ? 'Retry in ${widget.retryAfterSeconds}s'
                    : 'Send SMS',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.item, required this.currency});
  final MessageRecord item;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      DeliveryStatus.delivered => Colors.teal,
      DeliveryStatus.failed => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.primary,
    };
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      leading: Icon(
        item.status == DeliveryStatus.delivered
            ? Icons.check_circle_outline
            : Icons.schedule,
        color: color,
      ),
      title: Text(item.recipient),
      subtitle: SelectableText(
        '${item.messageId} • ${item.segmentCount} segment${item.segmentCount == 1 ? '' : 's'}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            item.status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(item.cost.format()),
        ],
      ),
    );
  }
}
