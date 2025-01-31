# Query Procedure
## bayar_tunggakan
```
DELIMITER $$

CREATE PROCEDURE bayar_tunggakan(
    IN p_id_pelanggan INT, 
    IN p_jumlah INT
)
BEGIN
    DECLARE v_total_tunggakan INT;
    DECLARE v_saldo INT;
    DECLARE v_id_transaksi INT;

    -- Ambil total_tunggakan dan saldo pelanggan
    SELECT total_tunggakan, saldo 
    INTO v_total_tunggakan, v_saldo
    FROM tabel_pelanggan 
    WHERE id_pelanggan = p_id_pelanggan;
    
    -- Periksa apakah pelanggan ada
    IF v_total_tunggakan IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        -- Periksa apakah pembayaran lebih besar dari tunggakan
        IF p_jumlah > v_total_tunggakan THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Jumlah pembayaran melebihi total tunggakan';
        END IF;

        -- Periksa apakah saldo cukup untuk membayar tunggakan
        IF p_jumlah > v_saldo THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo pelanggan tidak cukup untuk membayar tunggakan';
        END IF;

        -- Kurangi total_tunggakan dan saldo pelanggan
        UPDATE tabel_pelanggan 
        SET total_tunggakan = total_tunggakan - p_jumlah,
            saldo = saldo - p_jumlah
        WHERE id_pelanggan = p_id_pelanggan;

        -- Catat transaksi pembayaran di tabel_transaksi
        INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
        VALUES (p_id_pelanggan, 'pembayaran tunggakan', p_jumlah, NOW());

        -- Ambil ID transaksi terakhir
        SET v_id_transaksi = LAST_INSERT_ID();

        -- Catat transaksi keuangan di tabel_keuangan
        INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
        VALUES (v_id_transaksi, p_jumlah, NOW());

        -- Kembalikan pesan sukses
        SELECT CONCAT('Pembayaran berhasil! Transaksi ID: ', v_id_transaksi, 
                      ', Sisa Tunggakan: ', (v_total_tunggakan - p_jumlah), 
                      ', Saldo Sekarang: ', (v_saldo - p_jumlah)) AS pesan;
    END IF;
END$$

DELIMITER ;
```

## buat_laporan_transaksi_periode 
```
DELIMITER //

CREATE PROCEDURE buat_laporan_transaksi_periode(
    IN p_tipe_laporan VARCHAR(10),  -- 'harian', 'bulanan', 'tahunan'
    IN p_tanggal DATE
)
BEGIN
    DECLARE v_total_transaksi INT;
    DECLARE v_total_pembayaran INT;
    DECLARE v_total_pengiriman INT;
    DECLARE v_tanggal_mulai DATE;
    DECLARE v_tanggal_akhir DATE;

    -- Menentukan rentang tanggal berdasarkan tipe laporan yang diminta
    IF p_tipe_laporan = 'harian' THEN
        SET v_tanggal_mulai = p_tanggal;
        SET v_tanggal_akhir = p_tanggal;
    ELSEIF p_tipe_laporan = 'bulanan' THEN
        SET v_tanggal_mulai = DATE_FORMAT(p_tanggal, '%Y-%m-01');
        SET v_tanggal_akhir = LAST_DAY(p_tanggal);
    ELSEIF p_tipe_laporan = 'tahunan' THEN
        SET v_tanggal_mulai = DATE_FORMAT(p_tanggal, '%Y-01-01');
        SET v_tanggal_akhir = DATE_FORMAT(p_tanggal, '%Y-12-31');
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipe laporan tidak valid';
    END IF;

    -- Menghitung total transaksi untuk periode yang ditentukan
    SELECT COUNT(*) INTO v_total_transaksi
    FROM tabel_transaksi
    WHERE tanggal_transaksi BETWEEN v_tanggal_mulai AND v_tanggal_akhir;

    -- Menghitung total pembayaran untuk periode yang ditentukan
    -- Menggunakan kolom 'jumlah_pembayaran' pada tabel_keuangan
    SELECT SUM(jumlah_pembayaran) INTO v_total_pembayaran
    FROM tabel_keuangan
    WHERE tanggal_pembayaran BETWEEN v_tanggal_mulai AND v_tanggal_akhir;

    -- Menghitung total pengiriman untuk periode yang ditentukan
    SELECT SUM(biaya_pengiriman) INTO v_total_pengiriman
    FROM tabel_pengiriman
    WHERE tanggal_pengiriman BETWEEN v_tanggal_mulai AND v_tanggal_akhir;

    -- Menyimpan data laporan transaksi ke dalam tabel_laporan_transaksi
    INSERT INTO tabel_laporan_transaksi(tanggal, total_transaksi, total_pembayaran, total_pengiriman)
    VALUES (p_tanggal, v_total_transaksi, v_total_pembayaran, v_total_pengiriman);

    SELECT CONCAT('Laporan transaksi untuk periode ', p_tipe_laporan, ' berhasil dibuat') AS status;
END //

DELIMITER ;
```

## tambah_admin
```
DELIMITER $$

CREATE PROCEDURE tambah_admin(
    IN p_id_cabang INT,
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(100),
    IN p_hak_akses VARCHAR(50),
    IN p_nomor_telepon VARCHAR(20)
)
BEGIN
    -- Menambahkan admin ke tabel tabel_admin
    INSERT INTO tabel_admin (id_cabang, username, password, hak_akses, nomor_telepon)
    VALUES (p_id_cabang, p_username, p_password, p_hak_akses, p_nomor_telepon);

    -- Mengembalikan konfirmasi
    SELECT CONCAT('Admin ', p_username, ' dengan hak akses ', p_hak_akses, ' telah berhasil ditambahkan ke cabang ID ', p_id_cabang) AS pesan;
END$$

DELIMITER ;
```

## tambah_barang_dan_pengiriman
```
DELIMITER $$

CREATE PROCEDURE tambah_barang_dan_pengiriman(
    IN p_id_pelanggan INT, 
    IN p_deskripsi VARCHAR(255), 
    IN p_berat INT, 
    IN p_tujuan VARCHAR(255),
    IN p_jumlah_paket INT,
    IN p_id_ekspedisi INT,
    IN p_id_cs INT
)
BEGIN
    DECLARE v_saldo_pelanggan INT;
    DECLARE v_biaya_pengiriman INT;
    DECLARE v_nomor_resi VARCHAR(20);
    DECLARE v_id_barang INT;
    DECLARE v_id_pengiriman INT;
    
    -- Ambil saldo pelanggan
    SELECT saldo INTO v_saldo_pelanggan 
    FROM tabel_pelanggan 
    WHERE id_pelanggan = p_id_pelanggan;

    -- Periksa apakah pelanggan ada
    IF v_saldo_pelanggan IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        -- Hitung biaya pengiriman (misal: 5000 per kg + 2000 per paket)
        SET v_biaya_pengiriman = (p_berat * 5000) + (p_jumlah_paket * 2000);

        -- Periksa apakah saldo cukup
        IF v_saldo_pelanggan < v_biaya_pengiriman THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo pelanggan tidak mencukupi untuk biaya pengiriman';
        ELSE
            -- Generate nomor resi unik
            SET v_nomor_resi = CONCAT('RESI', UNIX_TIMESTAMP(NOW()), LPAD(FLOOR(RAND() * 1000), 3, '0'));

            -- Tambah data barang
            INSERT INTO tabel_barang (deskripsi, berat, tujuan, id_pelanggan, id_ekspedisi)
            VALUES (p_deskripsi, p_berat, p_tujuan, p_id_pelanggan, p_id_ekspedisi);

            -- Ambil ID barang yang baru ditambahkan
            SET v_id_barang = LAST_INSERT_ID();

            -- Tambah data pengiriman
            INSERT INTO tabel_pengiriman (nomor_resi, id_barang, status, tanggal_pengiriman, lokasi_asal, lokasi_tujuan, berat, jumlah_paket, biaya_pengiriman, id_cs)
            VALUES (v_nomor_resi, v_id_barang, 'Dalam Proses', NOW(), 'Gudang Utama', p_tujuan, p_berat, p_jumlah_paket, v_biaya_pengiriman, p_id_cs);

            -- Ambil ID pengiriman yang baru dibuat
            SET v_id_pengiriman = LAST_INSERT_ID();

            -- Update ID pengiriman di tabel barang
            UPDATE tabel_barang 
            SET id_pengiriman = v_id_pengiriman 
            WHERE id_barang = v_id_barang;

            -- Kurangi saldo pelanggan
            UPDATE tabel_pelanggan 
            SET saldo = saldo - v_biaya_pengiriman 
            WHERE id_pelanggan = p_id_pelanggan;

            -- Catat transaksi pembayaran biaya pengiriman
            INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
            VALUES (p_id_pelanggan, 'pembayaran biaya pengiriman', v_biaya_pengiriman, NOW());

            -- Ambil ID transaksi terakhir
            SET @v_id_transaksi = LAST_INSERT_ID();

            -- Catat transaksi keuangan
            INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
            VALUES (@v_id_transaksi, v_biaya_pengiriman, NOW());

            -- Kembalikan pesan sukses
            SELECT CONCAT('Barang berhasil dikirim! Nomor Resi: ', v_nomor_resi, 
                          ', Biaya Pengiriman: Rp', v_biaya_pengiriman, 
                          ', Saldo Tersisa: Rp', (v_saldo_pelanggan - v_biaya_pengiriman)) AS pesan;
        END IF;
    END IF;
END$$

DELIMITER ;
```

## tambah_cabang_ekspedisi
```
DELIMITER $$

CREATE PROCEDURE tambah_cabang_ekspedisi(
    IN p_nama_cabang VARCHAR(100),
    IN p_lokasi VARCHAR(100),
    IN p_id_ekspedisi INT
)
BEGIN
    -- Menambahkan cabang ekspedisi ke tabel
    INSERT INTO tabel_cabang_ekspedisi (nama_cabang, lokasi, id_ekspedisi)
    VALUES (p_nama_cabang, p_lokasi, p_id_ekspedisi);

    -- Memberikan konfirmasi bahwa cabang ekspedisi berhasil ditambahkan
    SELECT CONCAT('Cabang ekspedisi ', p_nama_cabang, ' di lokasi ', p_lokasi, ' telah berhasil ditambahkan untuk ekspedisi ID ', p_id_ekspedisi) AS pesan;
END$$

DELIMITER ;
```

## tambah_customer_service
```
DELIMITER $$

CREATE PROCEDURE tambah_customer_service(
    IN p_nama_cs VARCHAR(100),
    IN p_id_cabang INT
)
BEGIN
    -- Menambahkan customer service ke tabel tabel_costumer_service
    INSERT INTO tabel_costumer_service (nama_cs, id_cabang)
    VALUES (p_nama_cs, p_id_cabang);

    -- Mengembalikan konfirmasi
    SELECT CONCAT('Customer Service ', p_nama_cs, ' telah berhasil ditambahkan ke cabang ID ', p_id_cabang) AS pesan;
END$$

DELIMITER ;
```

## tambah_ekspedisi
```
DELIMITER $$

CREATE PROCEDURE tambah_ekspedisi(
    IN p_nama VARCHAR(100),
    IN p_status VARCHAR(50)
)
BEGIN
    -- Menambahkan ekspedisi ke tabel
    INSERT INTO tabel_ekspedisi (nama, status)
    VALUES (p_nama, p_status);

    -- Memberikan konfirmasi bahwa ekspedisi berhasil ditambahkan
    SELECT CONCAT('Ekspedisi ', p_nama, ' dengan status ', p_status, ' telah berhasil ditambahkan.') AS pesan;
END$$

DELIMITER ;
```

## tambah_kurir
```
DELIMITER $$

CREATE PROCEDURE tambah_kurir(
    IN p_nama_kurir VARCHAR(100),
    IN p_plat_kendaraan VARCHAR(20),
    IN p_jenis_kendaraan VARCHAR(50),
    IN p_id_cabang INT
)
BEGIN
    -- Menambahkan kurir ke tabel kurir
    INSERT INTO tabel_kurir (nama_kurir, plat_kendaraan, jenis_kendaraan, id_cabang)
    VALUES (p_nama_kurir, p_plat_kendaraan, p_jenis_kendaraan, p_id_cabang);

    -- Memberikan konfirmasi bahwa kurir telah berhasil ditambahkan
    SELECT CONCAT('Kurir ', p_nama_kurir, ' dengan plat kendaraan ', p_plat_kendaraan, ' dan jenis kendaraan ', p_jenis_kendaraan, ' telah berhasil ditambahkan ke cabang ID ', p_id_cabang) AS pesan;
END$$

DELIMITER ;
```

## tambah_pelanggan
```
DELIMITER //

CREATE PROCEDURE tambah_pelanggan(
    IN p_nama VARCHAR(255),
    IN p_alamat VARCHAR(255),
    IN p_nomor_telepon VARCHAR(20),
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(50),
    IN p_saldo INT,
    IN p_limit_pinjam INT
)
BEGIN
    INSERT INTO tabel_pelanggan (nama, alamat, nomor_telepon, username, password, saldo, limit_pinjam)
    VALUES (p_nama, p_alamat, p_nomor_telepon, p_username, p_password, p_saldo, p_limit_pinjam);
END //

DELIMITER ;
```

## tambah_saldo_pelanggan
```
DELIMITER $$

CREATE PROCEDURE tambah_saldo_pelanggan(
    IN p_id_pelanggan INT, 
    IN p_jumlah INT
)
BEGIN
    DECLARE v_id_transaksi INT;

    -- Periksa apakah pelanggan ada
    IF (SELECT COUNT(*) FROM tabel_pelanggan WHERE id_pelanggan = p_id_pelanggan) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        -- Update saldo pelanggan
        UPDATE tabel_pelanggan 
        SET saldo = saldo + p_jumlah
        WHERE id_pelanggan = p_id_pelanggan;

        -- Catat transaksi top-up di tabel_transaksi
        INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
        VALUES (p_id_pelanggan, 'top-up saldo', p_jumlah, NOW());

        -- Ambil ID transaksi terakhir
        SET v_id_transaksi = LAST_INSERT_ID();

        -- Catat transaksi keuangan di tabel_keuangan
        INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
        VALUES (v_id_transaksi, p_jumlah, NOW());

        -- Kembalikan pesan sukses
        SELECT CONCAT('Top-up berhasil! Transaksi ID: ', v_id_transaksi, ', Saldo sekarang: ', 
                      (SELECT saldo FROM tabel_pelanggan WHERE id_pelanggan = p_id_pelanggan)) AS pesan;
    END IF;
END$$

DELIMITER ;
```

## tambah_saldo_pinjam
```
DELIMITER $$

CREATE PROCEDURE tambah_saldo_pinjam(
    IN p_id_pelanggan INT, 
    IN p_jumlah INT
)
BEGIN
    DECLARE v_limit_pinjam INT;
    DECLARE v_total_tunggakan INT;
    DECLARE v_saldo INT;
    DECLARE v_id_transaksi INT;

    -- Ambil limit pinjaman, total tunggakan, dan saldo pelanggan
    SELECT limit_pinjaman, total_tunggakan, saldo 
    INTO v_limit_pinjam, v_total_tunggakan, v_saldo
    FROM tabel_pelanggan 
    WHERE id_pelanggan = p_id_pelanggan;
    
    -- Periksa apakah pelanggan ada
    IF v_limit_pinjam IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        -- Periksa apakah pinjaman melebihi batas
        IF (v_total_tunggakan + p_jumlah) > v_limit_pinjam THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo pinjaman sudah limit. Lunasi tunggakan terlebih dahulu';
        ELSE
            -- Update total_tunggakan dan saldo pelanggan
            UPDATE tabel_pelanggan 
            SET total_tunggakan = total_tunggakan + p_jumlah,
                saldo = saldo + p_jumlah
            WHERE id_pelanggan = p_id_pelanggan;
            
            -- Catat transaksi pinjaman di tabel_transaksi
            INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
            VALUES (p_id_pelanggan, 'pinjaman saldo', p_jumlah, NOW());
            
            -- Ambil ID transaksi terakhir
            SET v_id_transaksi = LAST_INSERT_ID();
            
            -- Catat transaksi keuangan di tabel_keuangan
            INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
            VALUES (v_id_transaksi, p_jumlah, NOW());

            -- Kembalikan pesan sukses
            SELECT CONCAT('Pinjaman berhasil! Transaksi ID: ', v_id_transaksi, ', Total Tunggakan: ', 
                          (v_total_tunggakan + p_jumlah)) AS pesan;
        END IF;
    END IF;
END$$

DELIMITER ;
```

## update_status_pengiriman_kurir
```
DELIMITER $$

CREATE PROCEDURE update_status_pengiriman_kurir(
    IN p_id_pengiriman INT,
    IN p_status VARCHAR(50),
    IN p_id_penerima INT,
    IN p_nama_penerima VARCHAR(255),
    IN p_alamat_penerima TEXT,
    IN p_kontak_penerima VARCHAR(20)
)
BEGIN
    DECLARE v_id_barang INT;
    DECLARE v_pengiriman_status VARCHAR(50);

    -- Cek apakah pengiriman ada
    SELECT status, id_barang INTO v_pengiriman_status, v_id_barang 
    FROM tabel_pengiriman 
    WHERE id_pengiriman = p_id_pengiriman;

    IF v_pengiriman_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pengiriman tidak ditemukan';
    ELSE
        -- Update status pengiriman
        UPDATE tabel_pengiriman 
        SET status = p_status 
        WHERE id_pengiriman = p_id_pengiriman;

        -- Jika status berubah menjadi 'Terkirim', maka data penerima harus disimpan
        IF p_status = 'Terkirim' THEN
            -- Cek apakah penerima sudah ada
            IF NOT EXISTS (SELECT 1 FROM tabel_penerima WHERE id_penerima = p_id_penerima) THEN
                -- Tambah data penerima
                INSERT INTO tabel_penerima (id_penerima, nama_penerima, alamat_penerima, kontak_penerima)
                VALUES (p_id_penerima, p_nama_penerima, p_alamat_penerima, p_kontak_penerima);
            END IF;

            -- Tambahkan data barang ke penerima dengan tanggal_diterima
            INSERT INTO barang_penerima (id_barang, id_pengiriman, tanggal_diterima)
            VALUES (v_id_barang, p_id_pengiriman, NOW());

            -- Berikan pesan sukses
            SELECT CONCAT('Status pengiriman berhasil diperbarui menjadi ', p_status, 
                          '. Barang telah diterima oleh ', p_nama_penerima) AS pesan;
        ELSE
            -- Berikan pesan sukses untuk status selain 'Terkirim'
            SELECT CONCAT('Status pengiriman berhasil diperbarui menjadi ', p_status) AS pesan;
        END IF;
    END IF;
END$$

DELIMITER ;
```

## update_status_pengiriman_lokasi
```
DELIMITER $$

CREATE PROCEDURE update_status_pengiriman_lokasi(
    IN p_id_pengiriman INT,
    IN p_status VARCHAR(50)
)
BEGIN
    DECLARE v_pengiriman_status VARCHAR(50);

    -- Cek apakah pengiriman ada
    SELECT status INTO v_pengiriman_status 
    FROM tabel_pengiriman 
    WHERE id_pengiriman = p_id_pengiriman;

    IF v_pengiriman_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pengiriman tidak ditemukan';
    ELSE
        -- Update status pengiriman
        UPDATE tabel_pengiriman 
        SET status = p_status 
        WHERE id_pengiriman = p_id_pengiriman;

        -- Berikan pesan sukses
        SELECT CONCAT('Status pengiriman berhasil diperbarui menjadi ', p_status) AS pesan;
    END IF;
END$$

DELIMITER ;
```

##  lihat_pengiriman_berdasarkan_resi
```
DELIMITER $$

CREATE PROCEDURE lihat_pengiriman_berdasarkan_resi(
    IN p_nomor_resi VARCHAR(50)
)
BEGIN
    -- Menampilkan data pengiriman berdasarkan nomor resi
    SELECT * 
    FROM tabel_pengiriman
    WHERE nomor_resi = p_nomor_resi;
END $$

DELIMITER ;
```
