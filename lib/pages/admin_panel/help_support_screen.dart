import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // FAQ Data
  final List<Map<String, String>> faqs = const [
    {
      "question": "How do I manage bookings?",
      "answer":
          "Go to the Bookings section where you can approve, reject, or modify bookings.",
    },
    {
      "question": "How do I reset my password?",
      "answer": "Go to Settings > Change Password and follow the instructions.",
    },
    {
      "question": "How can I contact support?",
      "answer":
          "You can reach us via email at support@sportify.com or call +92 300 1234567.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQs Section
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  return ExpansionTile(
                    title: Text(
                      faqs[index]["question"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(faqs[index]["answer"]!),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Contact Support Section
            const SizedBox(height: 20),
            const Text(
              "Need More Help?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: const Text("Email Support"),
                  subtitle: const Text("support@sportify.com"),
                  onTap: () {} //_launchEmail(),
                  ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text("Call Support"),
                  subtitle: const Text("+92 300 1234567"),
                  onTap: () {} //_launchPhone(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to launch email
  // void _launchEmail() async {
  //   final Uri emailUri = Uri(
  //     scheme: 'mailto',
  //     path: 'support@sportify.com',
  //     query: 'subject=Help Request&body=Describe your issue here...',
  //   );
  //   if (await canLaunchUrl(emailUri)) {
  //     await launchUrl(emailUri);
  //   }
  // }

  // // Function to launch phone dialer
  // void _launchPhone() async {
  //   final Uri phoneUri = Uri(scheme: 'tel', path: '+923001234567');
  //   if (await canLaunchUrl(phoneUri)) {
  //     await launchUrl(phoneUri);
  //   }
  // }
}
