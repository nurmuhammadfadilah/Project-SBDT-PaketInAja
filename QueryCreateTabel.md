# Query Create Table
1. barang_penerima
```
CREATE TABLE barang_penerima (
    id_barang INT,
    id_pengiriman INT,
    tanggal_diterima DATE,
    PRIMARY KEY (id_barang, id_pengiriman),
    FOREIGN KEY (id_barang) REFERENCES tabel_barang(id_barang),
    FOREIGN KEY (id_pengiriman) REFERENCES tabel_pengiriman(id_pengiriman)
);
```

2. tabel_admin
```
CREATE TABLE tabel_admin (
    id_admin INT AUTO_INCREMENT PRIMARY KEY,
    id_cabang INT,
    username VARCHAR(50),
    password VARCHAR(255),
    hak_akses VARCHAR(50),
    nomor_telepon VARCHAR(20),
    FOREIGN KEY (id_cabang) REFERENCES tabel_cabang_ekspedisi(id_cabang)
);
```

3. tabel_barang
```
CREATE TABLE tabel_barang (
    id_barang INT AUTO_INCREMENT PRIMARY KEY,
    deskripsi VARCHAR(255),
    berat DECIMAL(10, 2),
    tujuan VARCHAR(100),
    id_pengiriman INT,
    id_pelanggan INT,
    id_ekspedisi INT,
    FOREIGN KEY (id_pengiriman) REFERENCES tabel_pengiriman(id_pengiriman),
    FOREIGN KEY (id_pelanggan) REFERENCES tabel_pelanggan(id_pelanggan),
    FOREIGN KEY (id_ekspedisi) REFERENCES tabel_ekspedisi(id_ekspedisi)
);
```

4. tabel_cabang_ekspedisi
```
CREATE TABLE tabel_cabang_ekspedisi (
    id_cabang INT AUTO_INCREMENT PRIMARY KEY,
    nama_cabang VARCHAR(100),
    lokasi VARCHAR(255),
    id_ekspedisi INT,
    FOREIGN KEY (id_ekspedisi) REFERENCES tabel_ekspedisi(id_ekspedisi)		
);
```

5. tabel_customer_service
```
CREATE TABLE tabel_customer_service (
    id_cs INT AUTO_INCREMENT PRIMARY KEY,
    id_cabang INT,
    nama_cs VARCHAR(100),
    FOREIGN KEY (id_cabang) REFERENCES tabel_cabang_ekspedisi(id_cabang)
);
```

6. tabel_ekspedisi
```
CREATE TABLE tabel_ekspedisi (
    id_ekspedisi INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100),
    status VARCHAR(50)
);
```

7. tabel_keuangan
```
CREATE TABLE tabel_keuangan (
    id_transaksi INT,
    jumlah_pembayaran DECIMAL(10, 2),
    tanggal_pembayaran DATE,
    PRIMARY KEY (id_transaksi),
    FOREIGN KEY (id_transaksi) REFERENCES tabel_transaksi(id_transaksi)
);
```

8. tabel_kurir
```
CREATE TABLE tabel_kurir (
    id_kurir INT AUTO_INCREMENT PRIMARY KEY,
    nama_kurir VARCHAR(100),
    plat_kendaraan VARCHAR(50),
    id_cabang INT,
    FOREIGN KEY (id_cabang) REFERENCES tabel_cabang_ekspedisi(id_cabang)
);
```


9. tabel_laporan_transaksi
```
CREATE TABLE tabel_laporan_transaksi (
    id_laporan INT AUTO_INCREMENT PRIMARY KEY,
    tanggal DATE,
    total_transaksi INT,
    total_pembayaran INT,
    total_pengiriman INT
);
```

10. tabel_pelanggan
```
CREATE TABLE tabel_pelanggan (
    id_pelanggan INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100),
    alamat VARCHAR(255),
    nomor_telepon VARCHAR(20),
    username VARCHAR(50),
    password VARCHAR(255),
    saldo DECIMAL(10, 2),
    limit_pinjam DECIMAL(10, 2),
    total_tunggakan DECIMAL(10, 2) DEFAULT 0
);
```

11. tabel_penerima
```
CREATE TABLE tabel_penerima (
    id_penerima INT AUTO_INCREMENT PRIMARY KEY,
    nama_penerima VARCHAR(100),
    alamat_penerima VARCHAR(255),
    kontak_penerima VARCHAR(20)
);
```

12. tabel_pengiriman
```
CREATE TABLE tabel_pengiriman (
    id_pengiriman INT AUTO_INCREMENT PRIMARY KEY,
    nomor_resi VARCHAR(50) UNIQUE,
    id_barang INT,
    status VARCHAR(50),
    tanggal_pengiriman DATE,
    lokasi_asal VARCHAR(255),
    lokasi_tujuan VARCHAR(255),
    berat DECIMAL(10, 2),
    jumlah_paket INT,
    biaya_pengiriman DECIMAL(10, 2),
    id_cs INT,
    FOREIGN KEY (id_barang) REFERENCES tabel_barang(id_barang),
    FOREIGN KEY (id_cs) REFERENCES tabel_customer_service(id_cs)
);
```

13. tabel_transaksi
```
CREATE TABLE tabel_transaksi (
    id_transaksi INT AUTO_INCREMENT PRIMARY KEY,
    id_pelanggan INT,
    jenis_transaksi VARCHAR(50),
    jumlah DECIMAL(10, 2),
    tanggal_transaksi DATE,
    FOREIGN KEY (id_pelanggan) REFERENCES tabel_pelanggan(id_pelanggan)
);
```