import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code/services/logout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BandaraTransitPergi extends StatefulWidget {
  @override
  _BandaraTransitPergiState createState() => _BandaraTransitPergiState();
}

class _BandaraTransitPergiState extends State<BandaraTransitPergi> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaPetugasController = TextEditingController();
  final TextEditingController kloterKeberangkatanController =
      TextEditingController();

  final List<String> taskDescriptions = [
    '1.Pastikan semua jamaah sudah berkumpul di titik pertemuan yang ditentukan sesuai dengan jadwal boarding.',
    '2.Lakukan pengecekan ulang jumlah untuk memastikan tidak ada yang tertinggal.',
    '3.Pastikan semua jamaah memiliki boarding pass dan paspor siap untuk diperiksa.',
    '4.Ingatkan jamaah untuk tetap tenang dan mengikuti instruksi petugas bandara serta kru pesawat.',
    '5.Pastikan jamaah duduk di tempat yang telah ditentukan dan merasa nyaman',
    '6.Pastikan jamaah menyimpan paspor, tiket, dan dokumen penting lainnya dengan aman selama penerbangan.',
    '7.Bantu jamaah jika ada kebutuhan khusus selama penerbangan.',
    '8.Sampaikan infomasi penting mengenai prosedur yang akan dilakukan setibanya di Bandara Tujuan.',
  ];

  List<int?> selectedOptions = List<int?>.filled(8, null);
  List<Map<String, dynamic>> kloterList = [];
  int? selectedKloterId; // Store selected kloter ID
  final double fontSize = 14.0; // Define fontSize variable

  @override
  void initState() {
    super.initState();
    fetchKloterData(); // Load kloter data on initialization
  }

  Future<void> fetchKloterData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('Token');
    final url = Uri.parse(
        "http://192.168.1.56:8000/api/kloter"); // Adjust to your endpoint

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          kloterList = data
              .map((item) => {"id": item['id'], "nama": item['nama']})
              .toList();
        });
      } else if (response.statusCode == 401) {
        await logout(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil data kloter")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> submitData() async {
    if (_formKey.currentState!.validate() && !selectedOptions.contains(null)) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token');
      final url = Uri.parse(
          "http://192.168.1.56:8000/api/tugas"); // Use your actual Laravel endpoint

      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode({
            "nama": "Bandara Transit (Pergi)",
            "kloter": selectedKloterId,
            "tugas_type": 5,
            "tasks": selectedOptions.map((e) => e.toString()).join(", "),
            "title": taskDescriptions.map((e) => e.toString()).join(", ")
          }),
        );
        print(response);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Data berhasil dikirim")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal mengirim data")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tolong semua data diisi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ceklis Bandara Transit (Berangkat)'),
        backgroundColor: Colors.purple,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: selectedKloterId,
                hint: Text("Pilih Kloter Keberangkatan"),
                onChanged: (value) {
                  setState(() {
                    selectedKloterId = value;
                  });
                },
                items: kloterList.map<DropdownMenuItem<int>>((kloter) {
                  return DropdownMenuItem<int>(
                    value: kloter["id"],
                    child: Text(kloter["nama"]),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Kloter Keberangkatan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  return value == null
                      ? 'Kloter Keberangkatan is required'
                      : null;
                },
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: taskDescriptions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              taskDescriptions[index],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Radio(
                                  value: 0,
                                  groupValue: selectedOptions[index],
                                  onChanged: (int? value) {
                                    setState(() {
                                      selectedOptions[index] = value;
                                    });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize
                                      .shrinkWrap, // Memperkecil area klik
                                ),
                                Text(
                                  'Sudah',
                                  style: TextStyle(
                                    fontSize:
                                        fontSize * 0.9, // Sesuaikan ukuran teks
                                  ),
                                ),
                                Radio(
                                  value: 1,
                                  groupValue: selectedOptions[index],
                                  onChanged: (int? value) {
                                    setState(() {
                                      selectedOptions[index] = value;
                                    });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize
                                      .shrinkWrap, // Memperkecil area klik
                                ),
                                Text(
                                  'Tidak Terpenuhi',
                                  style: TextStyle(
                                    fontSize:
                                        fontSize * 0.9, // Sesuaikan ukuran teks
                                  ),
                                ),
                                Radio(
                                  value: 2,
                                  groupValue: selectedOptions[index],
                                  onChanged: (int? value) {
                                    setState(() {
                                      selectedOptions[index] = value;
                                    });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize
                                      .shrinkWrap, // Memperkecil area klik
                                ),
                                Flexible(
                                  child: Text(
                                    'Dikerjakan oleh Rekan',
                                    style: TextStyle(
                                      fontSize: fontSize *
                                          0.9, // Sesuaikan ukuran teks
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Menghindari teks terlalu panjang
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: submitData,
                child: Text(
                  'Laporkan',
                  style: TextStyle(
                      color: Colors.white), // Change the text color here
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      Colors.purple, // Text color when the button is pressed
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
