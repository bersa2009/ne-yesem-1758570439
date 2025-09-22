import 'package:flutter/material.dart';

class ResetScreen extends StatelessWidget {
  const ResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asetlem')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veri Yönetimi',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Tüm Verileri Sil'),
                subtitle: const Text('Favoriler, ayarlar ve önbellek temizlenir'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Emin misiniz?'),
                      content: const Text('Bu işlem tüm verilerinizi silecek ve geri alınamaz.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Gerçek veri silme işlemi burada yapılacak
                            // Şimdilik sadece bildirim göster
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bu özellik henüz implementasyonsuz'))
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text('Sil', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('Ayarları Sıfırla'),
                subtitle: const Text('Sadece uygulama ayarları sıfırlanır'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Ayarları Sıfırla'),
                      content: const Text('Bu işlem uygulama ayarlarını varsayılana döndürecek.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Gerçek ayar sıfırlama işlemi burada yapılacak
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bu özellik henüz implementasyonsuz'))
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text('Sıfırla'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.blue),
                title: const Text('Profil'),
                subtitle: const Text('Kullanıcı bilgileri ve tercihleri'),
                onTap: () {
                  // Profil ekranı henüz implementasyonsuz
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil özelliği henüz implementasyonsuz'))
                  );
                },
              ),
            ),
            const Spacer(),
            const Text(
              'Uyarı: Veri silme işlemleri geri alınamaz.',
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}