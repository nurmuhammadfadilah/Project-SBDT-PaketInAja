# Project-SBDT-PaketInAja
## Introduction
PaketInAja adalah sistem berbasis database yang dirancang untuk mengelola seluruh proses pengiriman barang dari pelanggan hingga penerima, termasuk manajemen pengiriman, pembayaran, dan pelaporan keuangan. Sistem ini mengintegrasikan berbagai entitas seperti pelanggan, kurir, cabang ekspedisi, customer service, dan admin untuk mendukung kelancaran operasional dalam layanan ekspedisi. Tujuan dari proyek PaketInAja ini adalah untuk memenuhi tugas Proyek Akhir Semester dengan merancang sebuah sistem basis data terdistribusi yang mampu mengelola seluruh proses operasional ekspedisi secara efisien dan terstruktur.

- download file ```paketinaja.sql``` atau git clone
```
git clone https://github.com/nurmuhammadfadilah/Project-SBDT-PaketInAja.git
```
- Lalu nyalakan XAMPP, pada browser buka [localhost/phpMyAdmin](http://localhost/phpmyadmin) 
- buat database
- import ```paketinaja.sql``` ke dalam database
- buka terminal XAMPP untuk oprasionalnya 
```
cd mysql/bin
```
- masuk ke database
```
mysql -u root -p (nama database)
```

## CALL method untuk pengoprasian SQL
1. Membuat role admin
```
CALL tambah_admin(1, 'admin123', 'adminpass', 'superadmin', '081234567890');
```
-- ID cabang = 1, username = 'admin123', password = 'adminpass', hak akses = 'superadmin', nomor telepon = '081234567890'

2. Menambah cabang ekspedisi
```
CALL tambah_cabang_ekspedisi(2, 'PaketInAja Jakarta', 'Jakarta');
```
-- ID ekspedisi = 2, Nama cabang = 'PaketInAja Jakarta', Lokasi cabang = 'Jakarta'

3. Menambah customer service
```
CALL tambah_customer_service('Siti', 2);
```
-- Nama CS = 'Siti', Cabang = 2

4. Menambah kurir
```
CALL tambah_kurir('Arie', 'B 1030 CD', 'motor', 2);
``` 
-- Nama kurir = 'Arie', no kendaraan =  'B 1030 CD', jenis kendaraan = 'motor',  cabang = 2

5. Membuat data pelanggan baru
``` 
CALL tambah_pelanggan('Jane Doe', 'Jl. Merdeka No.11, Jakarta', '085234567890', 'janedoe', 'password123', 0, 50000, 0);
```
-- nama = 'Jane Doe', alamat =  'Jl. Merdeka No.11, Jakarta', nomor telepon = '085234567890', username =  'janedoe', password =  'password123', saldo = 0,  limit pinjam = 50000, total tunggakan = 0

6. Tambah saldo pelanggan
```
CALL tambah_saldo_pelanggan(1, 50000);
``` 
-- id pelanggan = 1, jumlah top up saldo = 50000

7. Tambah pinjaman pelanggan
```
CALL tambah_saldo_pinjam(1, 30000);
```
-- id pelanggan = 1, jumlah pinjaman = 30000

8. Pelanggan membayar tunggakan
```
CALL bayar_tunggakan(1, 10000);
```
-- -- id pelanggan = 1, jumlah pembayaran = 30000

9. data barang yang ingin dikirim
 ```
CALL tambah_barang_dan_pengiriman(
    'Laptop', 
    5, 
    'Jakarta', -- lokasi tujuan di tabel_barang
    1,  -- ID pelanggan
    1,  -- ID ekspedisi 
    'dalam proses', --status
    '2025-01-20', -- waktu
    'Surabaya', -- lokasi asal
    'Jakarta', -- lokasi tujuan
    3,  -- Jumlah paket
    1   -- ID Customer Service
);
```

10. update status pengiriman
```
CALL update_status_pengiriman_kurir(
    6,  -- p_id_pengiriman
    'Terkirim',  -- p_status
    102,  -- p_id_penerima
    'Rudi Hartono',  -- p_nama_penerima
    'Jl. Sepuluh No. 15, Jakarta',  -- p_alamat_penerima
    '08123456789'  -- p_kontak_penerima
);
```

11. update lokasi barang
```
CALL update_status_pengiriman_lokasi(4, 'Cabang Jakarta');
```
id_pengiriman = 4, Status = 'Cabang Jakarta'

12. melihat data berdasarkan nomor resi
```
CALL lihat_pengiriman_berdasarkan_resi('RESI12345');
```
nomor resi = 'RESI12345`

13. pembuatan laporan
    - laporan harian
    ```
    CALL buat_laporan_transaksi_periode('harian', '2025-01-20'); 
    ``` 
    Untuk harian, laporan hanya akan dihitung untuk satu hari yang diberikan (v_tanggal_mulai = v_tanggal_akhir).
    - laporan bulanan
    ```
    CALL buat_laporan_transaksi_periode('bulanan', '2025-01-20');
    ```
    Untuk bulanan, rentang tanggal dimulai dari hari pertama bulan (v_tanggal_mulai) hingga hari terakhir bulan tersebut (v_tanggal_akhir).
    - laporan tahunan
    ```
    CALL buat_laporan_transaksi_periode('tahunan', '2025-01-20');
    ```
    Untuk tahunan, rentang tanggal dimulai dari 1 Januari hingga 31 Desember tahun yang bersangkutan.
