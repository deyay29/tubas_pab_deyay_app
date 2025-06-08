import 'package:flutter/material.dart';
import 'package:tubas_pab_deyay_app/pages/admin_page.dart';
import 'package:tubas_pab_deyay_app/pages/daftardosen_page.dart';
import 'package:tubas_pab_deyay_app/pages/daftarkelas_page.dart';
import 'package:tubas_pab_deyay_app/pages/daftarmahasiswa_page.dart';
import 'package:tubas_pab_deyay_app/pages/daftarmatkul_page.dart';
import 'package:tubas_pab_deyay_app/pages/dosen_page.dart';
import 'package:tubas_pab_deyay_app/pages/login_page.dart';
import 'package:tubas_pab_deyay_app/pages/mahasiswa_page.dart';
import 'package:tubas_pab_deyay_app/route/routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case Routes.admin:
        return MaterialPageRoute(builder: (_) => const AdminPage());

      case Routes.daftarDosen:
        return MaterialPageRoute(builder: (_) => const DaftarDosenPage());

      case Routes.daftarMahasiswa:
        return MaterialPageRoute(builder: (_) => const DaftarMahasiswaPage());

      case Routes.daftarKelas:
        return MaterialPageRoute(builder: (_) => const DaftarKelasPage());

      case Routes.daftarMatkul:
        return MaterialPageRoute(builder: (_) => const DaftarMatkulPage());

      case Routes.dosen:
        // Tidak perlu argumen karena DosenPage sudah ambil data sendiri dari Firebase
        return MaterialPageRoute(builder: (_) => const DosenPage());

      case Routes.mahasiswa:
        // Sama, hapus argumen
        return MaterialPageRoute(builder: (_) => const MahasiswaPage());

      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
