-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 20, 2025 at 09:23 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `paketinaja`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `bayar_tunggakan` (IN `p_id_pelanggan` INT, IN `p_jumlah` INT)   BEGIN
    DECLARE v_total_tunggakan INT;
    DECLARE v_saldo INT;
    DECLARE v_id_transaksi INT;

    
    SELECT total_tunggakan, saldo 
    INTO v_total_tunggakan, v_saldo
    FROM tabel_pelanggan 
    WHERE id_pelanggan = p_id_pelanggan;
    
    
    IF v_total_tunggakan IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        
        IF p_jumlah > v_total_tunggakan THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Jumlah pembayaran melebihi total tunggakan';
        END IF;

        
        IF p_jumlah > v_saldo THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo pelanggan tidak cukup untuk membayar tunggakan';
        END IF;

        
        UPDATE tabel_pelanggan 
        SET total_tunggakan = total_tunggakan - p_jumlah,
            saldo = saldo - p_jumlah
        WHERE id_pelanggan = p_id_pelanggan;

        
        INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
        VALUES (p_id_pelanggan, 'pembayaran tunggakan', p_jumlah, NOW());

        
        SET v_id_transaksi = LAST_INSERT_ID();

        
        INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
        VALUES (v_id_transaksi, p_jumlah, NOW());

        
        SELECT CONCAT('Pembayaran berhasil! Transaksi ID: ', v_id_transaksi, 
                      ', Sisa Tunggakan: ', (v_total_tunggakan - p_jumlah), 
                      ', Saldo Sekarang: ', (v_saldo - p_jumlah)) AS pesan;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `buat_laporan_transaksi_periode` (IN `p_tipe_laporan` VARCHAR(10), IN `p_tanggal` DATE)   BEGIN
    DECLARE v_total_transaksi INT;
    DECLARE v_total_pembayaran INT;
    DECLARE v_total_pengiriman INT;
    DECLARE v_tanggal_mulai DATE;
    DECLARE v_tanggal_akhir DATE;

    
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

    
    SELECT COUNT(*) INTO v_total_transaksi
    FROM tabel_transaksi
    WHERE tanggal_transaksi BETWEEN v_tanggal_mulai AND v_tanggal_akhir;

    
    
    
    SELECT SUM(jumlah_pembayaran) INTO v_total_pembayaran
    FROM tabel_keuangan
    WHERE tanggal_pembayaran BETWEEN v_tanggal_mulai AND v_tanggal_akhir;

    
    SELECT SUM(jumlah_paket) INTO v_total_pengiriman
    FROM tabel_pengiriman
    WHERE tanggal_pengiriman BETWEEN v_tanggal_mulai AND v_tanggal_akhir;

    
    INSERT INTO tabel_laporan_transaksi(tanggal, total_transaksi, total_pembayaran, total_pengiriman)
    VALUES (p_tanggal, v_total_transaksi, v_total_pembayaran, v_total_pengiriman);

    SELECT CONCAT('Laporan transaksi untuk periode ', p_tipe_laporan, ' berhasil dibuat') AS status;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `lihat_pengiriman_berdasarkan_resi` (IN `p_nomor_resi` VARCHAR(50))   BEGIN
    
    SELECT * 
    FROM tabel_pengiriman
    WHERE nomor_resi = p_nomor_resi;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_admin` (IN `p_id_cabang` INT, IN `p_username` VARCHAR(100), IN `p_password` VARCHAR(100), IN `p_hak_akses` VARCHAR(50), IN `p_nomor_telepon` VARCHAR(20))   BEGIN
    
    INSERT INTO tabel_admin (id_cabang, username, password, hak_akses, nomor_telepon)
    VALUES (p_id_cabang, p_username, p_password, p_hak_akses, p_nomor_telepon);

    
    SELECT CONCAT('Admin ', p_username, ' dengan hak akses ', p_hak_akses, ' telah berhasil ditambahkan ke cabang ID ', p_id_cabang) AS pesan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_barang_dan_pengiriman` (IN `p_id_pelanggan` INT, IN `p_deskripsi` VARCHAR(255), IN `p_berat` INT, IN `p_tujuan` VARCHAR(255), IN `p_jumlah_paket` INT, IN `p_id_ekspedisi` INT, IN `p_id_cs` INT)   BEGIN
    DECLARE v_saldo_pelanggan INT;
    DECLARE v_biaya_pengiriman INT;
    DECLARE v_nomor_resi VARCHAR(20);
    DECLARE v_id_barang INT;
    DECLARE v_id_pengiriman INT;
    
    
    SELECT saldo INTO v_saldo_pelanggan 
    FROM tabel_pelanggan 
    WHERE id_pelanggan = p_id_pelanggan;

    
    IF v_saldo_pelanggan IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        
        SET v_biaya_pengiriman = (p_berat * 5000) + (p_jumlah_paket * 2000);

        
        IF v_saldo_pelanggan < v_biaya_pengiriman THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo pelanggan tidak mencukupi untuk biaya pengiriman';
        ELSE
            
            SET v_nomor_resi = CONCAT('RESI', UNIX_TIMESTAMP(NOW()), LPAD(FLOOR(RAND() * 1000), 3, '0'));

            
            INSERT INTO tabel_barang (deskripsi, berat, tujuan, id_pelanggan, id_ekspedisi)
            VALUES (p_deskripsi, p_berat, p_tujuan, p_id_pelanggan, p_id_ekspedisi);

            
            SET v_id_barang = LAST_INSERT_ID();

            
            INSERT INTO tabel_pengiriman (nomor_resi, id_barang, status, tanggal_pengiriman, lokasi_asal, lokasi_tujuan, berat, jumlah_paket, biaya_pengiriman, id_cs)
            VALUES (v_nomor_resi, v_id_barang, 'Dalam Proses', NOW(), 'Gudang Utama', p_tujuan, p_berat, p_jumlah_paket, v_biaya_pengiriman, p_id_cs);

            
            SET v_id_pengiriman = LAST_INSERT_ID();

            
            UPDATE tabel_barang 
            SET id_pengiriman = v_id_pengiriman 
            WHERE id_barang = v_id_barang;

            
            UPDATE tabel_pelanggan 
            SET saldo = saldo - v_biaya_pengiriman 
            WHERE id_pelanggan = p_id_pelanggan;

            
            INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
            VALUES (p_id_pelanggan, 'pembayaran biaya pengiriman', v_biaya_pengiriman, NOW());

            
            SET @v_id_transaksi = LAST_INSERT_ID();

            
            INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
            VALUES (@v_id_transaksi, v_biaya_pengiriman, NOW());

            
            SELECT CONCAT('Barang berhasil dikirim! Nomor Resi: ', v_nomor_resi, 
                          ', Biaya Pengiriman: Rp', v_biaya_pengiriman, 
                          ', Saldo Tersisa: Rp', (v_saldo_pelanggan - v_biaya_pengiriman)) AS pesan;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_cabang_ekspedisi` (IN `p_nama_cabang` VARCHAR(100), IN `p_lokasi` VARCHAR(100), IN `p_id_ekspedisi` INT)   BEGIN
    
    INSERT INTO tabel_cabang_ekspedisi (nama_cabang, lokasi, id_ekspedisi)
    VALUES (p_nama_cabang, p_lokasi, p_id_ekspedisi);

    
    SELECT CONCAT('Cabang ekspedisi ', p_nama_cabang, ' di lokasi ', p_lokasi, ' telah berhasil ditambahkan untuk ekspedisi ID ', p_id_ekspedisi) AS pesan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_customer_service` (IN `p_nama_cs` VARCHAR(100), IN `p_id_cabang` INT)   BEGIN
    
    INSERT INTO tabel_customer_service (nama_cs, id_cabang)
    VALUES (p_nama_cs, p_id_cabang);

    
    SELECT CONCAT('Customer Service ', p_nama_cs, ' telah berhasil ditambahkan ke cabang ID ', p_id_cabang) AS pesan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_ekspedisi` (IN `p_nama` VARCHAR(100), IN `p_status` VARCHAR(50))   BEGIN
    
    INSERT INTO tabel_ekspedisi (nama, status)
    VALUES (p_nama, p_status);

    
    SELECT CONCAT('Ekspedisi ', p_nama, ' dengan status ', p_status, ' telah berhasil ditambahkan.') AS pesan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_kurir` (IN `p_nama_kurir` VARCHAR(100), IN `p_plat_kendaraan` VARCHAR(20), IN `p_jenis_kendaraan` VARCHAR(50), IN `p_id_cabang` INT)   BEGIN
    
    INSERT INTO tabel_kurir (nama_kurir, plat_kendaraan, jenis_kendaraan, id_cabang)
    VALUES (p_nama_kurir, p_plat_kendaraan, p_jenis_kendaraan, p_id_cabang);

    
    SELECT CONCAT('Kurir ', p_nama_kurir, ' dengan plat kendaraan ', p_plat_kendaraan, ' dan jenis kendaraan ', p_jenis_kendaraan, ' telah berhasil ditambahkan ke cabang ID ', p_id_cabang) AS pesan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_pelanggan` (IN `p_nama` VARCHAR(255), IN `p_alamat` VARCHAR(255), IN `p_nomor_telepon` VARCHAR(20), IN `p_username` VARCHAR(50), IN `p_password` VARCHAR(50), IN `p_saldo` INT, IN `p_limit_pinjam` INT)   BEGIN
    INSERT INTO tabel_pelanggan (nama, alamat, nomor_telepon, username, password, saldo, limit_pinjam)
    VALUES (p_nama, p_alamat, p_nomor_telepon, p_username, p_password, p_saldo, p_limit_pinjam);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_saldo_pelanggan` (IN `p_id_pelanggan` INT, IN `p_jumlah` INT)   BEGIN
    DECLARE v_id_transaksi INT;

    
    IF (SELECT COUNT(*) FROM tabel_pelanggan WHERE id_pelanggan = p_id_pelanggan) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        
        UPDATE tabel_pelanggan 
        SET saldo = saldo + p_jumlah
        WHERE id_pelanggan = p_id_pelanggan;

        
        INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
        VALUES (p_id_pelanggan, 'top-up saldo', p_jumlah, NOW());

        
        SET v_id_transaksi = LAST_INSERT_ID();

        
        INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
        VALUES (v_id_transaksi, p_jumlah, NOW());

        
        SELECT CONCAT('Top-up berhasil! Transaksi ID: ', v_id_transaksi, ', Saldo sekarang: ', 
                      (SELECT saldo FROM tabel_pelanggan WHERE id_pelanggan = p_id_pelanggan)) AS pesan;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_saldo_pinjam` (IN `p_id_pelanggan` INT, IN `p_jumlah` INT)   BEGIN
    DECLARE v_limit_pinjam INT;
    DECLARE v_total_tunggakan INT;
    DECLARE v_saldo INT;
    DECLARE v_id_transaksi INT;

    
    SELECT limit_pinjam, total_tunggakan, saldo 
    INTO v_limit_pinjam, v_total_tunggakan, v_saldo
    FROM tabel_pelanggan 
    WHERE id_pelanggan = p_id_pelanggan;
    
    
    IF v_limit_pinjam IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pelanggan tidak ditemukan';
    ELSE
        
        IF (v_total_tunggakan + p_jumlah) > v_limit_pinjam THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo pinjaman sudah limit. Lunasi tunggakan terlebih dahulu';
        ELSE
            
            UPDATE tabel_pelanggan 
            SET total_tunggakan = total_tunggakan + p_jumlah,
                saldo = saldo + p_jumlah
            WHERE id_pelanggan = p_id_pelanggan;
            
            
            INSERT INTO tabel_transaksi (id_pelanggan, jenis_transaksi, jumlah, tanggal_transaksi)
            VALUES (p_id_pelanggan, 'pinjaman saldo', p_jumlah, NOW());
            
            
            SET v_id_transaksi = LAST_INSERT_ID();
            
            
            INSERT INTO tabel_keuangan (id_transaksi, jumlah_pembayaran, tanggal_pembayaran)
            VALUES (v_id_transaksi, p_jumlah, NOW());

            
            SELECT CONCAT('Pinjaman berhasil! Transaksi ID: ', v_id_transaksi, ', Total Tunggakan: ', 
                          (v_total_tunggakan + p_jumlah)) AS pesan;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_status_pengiriman_kurir` (IN `p_id_pengiriman` INT, IN `p_status` VARCHAR(50), IN `p_id_penerima` INT, IN `p_nama_penerima` VARCHAR(255), IN `p_alamat_penerima` TEXT, IN `p_kontak_penerima` VARCHAR(20))   BEGIN
    DECLARE v_id_barang INT;
    DECLARE v_pengiriman_status VARCHAR(50);

    
    SELECT status, id_barang INTO v_pengiriman_status, v_id_barang 
    FROM tabel_pengiriman 
    WHERE id_pengiriman = p_id_pengiriman;

    IF v_pengiriman_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pengiriman tidak ditemukan';
    ELSE
        
        UPDATE tabel_pengiriman 
        SET status = p_status 
        WHERE id_pengiriman = p_id_pengiriman;

        
        IF p_status = 'Terkirim' THEN
            
            IF NOT EXISTS (SELECT 1 FROM tabel_penerima WHERE id_penerima = p_id_penerima) THEN
                
                INSERT INTO tabel_penerima (id_penerima, nama_penerima, alamat_penerima, kontak_penerima)
                VALUES (p_id_penerima, p_nama_penerima, p_alamat_penerima, p_kontak_penerima);
            END IF;

            
            INSERT INTO barang_penerima (id_barang, id_penerima, tanggal_diterima)
            VALUES (v_id_barang, p_id_penerima, NOW());

            
            SELECT CONCAT('Status pengiriman berhasil diperbarui menjadi ', p_status, 
                          '. Barang telah diterima oleh ', p_nama_penerima) AS pesan;
        ELSE
            
            SELECT CONCAT('Status pengiriman berhasil diperbarui menjadi ', p_status) AS pesan;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_status_pengiriman_lokasi` (IN `p_id_pengiriman` INT, IN `p_status` VARCHAR(50))   BEGIN
    DECLARE v_pengiriman_status VARCHAR(50);

    
    SELECT status INTO v_pengiriman_status 
    FROM tabel_pengiriman 
    WHERE id_pengiriman = p_id_pengiriman;

    IF v_pengiriman_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pengiriman tidak ditemukan';
    ELSE
        
        UPDATE tabel_pengiriman 
        SET status = p_status 
        WHERE id_pengiriman = p_id_pengiriman;

        
        SELECT CONCAT('Status pengiriman berhasil diperbarui menjadi ', p_status) AS pesan;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `barang_penerima`
--

CREATE TABLE `barang_penerima` (
  `id_barang` int(11) NOT NULL,
  `id_penerima` int(11) NOT NULL,
  `tanggal_diterima` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `barang_penerima`
--

INSERT INTO `barang_penerima` (`id_barang`, `id_penerima`, `tanggal_diterima`) VALUES
(14, 102, '2025-01-21 01:01:39');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_admin`
--

CREATE TABLE `tabel_admin` (
  `id_admin` int(11) NOT NULL,
  `id_cabang` int(11) DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `hak_akses` varchar(50) DEFAULT NULL,
  `nomor_telepon` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_admin`
--

INSERT INTO `tabel_admin` (`id_admin`, `id_cabang`, `username`, `password`, `hak_akses`, `nomor_telepon`) VALUES
(2, 1, 'admin1', 'password123', 'superadmin', '08123456789');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_barang`
--

CREATE TABLE `tabel_barang` (
  `id_barang` int(11) NOT NULL,
  `deskripsi` varchar(255) DEFAULT NULL,
  `berat` int(11) DEFAULT NULL,
  `tujuan` varchar(100) DEFAULT NULL,
  `id_pengiriman` int(11) DEFAULT NULL,
  `id_pelanggan` int(11) DEFAULT NULL,
  `id_ekspedisi` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_barang`
--

INSERT INTO `tabel_barang` (`id_barang`, `deskripsi`, `berat`, `tujuan`, `id_pengiriman`, `id_pelanggan`, `id_ekspedisi`) VALUES
(13, 'Laptop', 5, 'Jakarta', 5, 1, 1),
(14, 'Laptop', 1, 'Jakarta', 6, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `tabel_cabang_ekspedisi`
--

CREATE TABLE `tabel_cabang_ekspedisi` (
  `id_cabang` int(11) NOT NULL,
  `nama_cabang` varchar(100) DEFAULT NULL,
  `lokasi` varchar(255) DEFAULT NULL,
  `id_ekspedisi` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_cabang_ekspedisi`
--

INSERT INTO `tabel_cabang_ekspedisi` (`id_cabang`, `nama_cabang`, `lokasi`, `id_ekspedisi`) VALUES
(1, 'PaketInAja Surabaya', 'Surabaya', 1);

-- --------------------------------------------------------

--
-- Table structure for table `tabel_customer_service`
--

CREATE TABLE `tabel_customer_service` (
  `id_cs` int(11) NOT NULL,
  `id_cabang` int(11) DEFAULT NULL,
  `nama_cs` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_customer_service`
--

INSERT INTO `tabel_customer_service` (`id_cs`, `id_cabang`, `nama_cs`) VALUES
(1, 1, 'Siti');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_ekspedisi`
--

CREATE TABLE `tabel_ekspedisi` (
  `id_ekspedisi` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_ekspedisi`
--

INSERT INTO `tabel_ekspedisi` (`id_ekspedisi`, `nama`, `status`) VALUES
(1, 'PaketInAja', 'Aktif');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_keuangan`
--

CREATE TABLE `tabel_keuangan` (
  `id_transaksi` int(11) DEFAULT NULL,
  `jumlah_pembayaran` int(11) DEFAULT NULL,
  `tanggal_pembayaran` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_keuangan`
--

INSERT INTO `tabel_keuangan` (`id_transaksi`, `jumlah_pembayaran`, `tanggal_pembayaran`) VALUES
(5, 50000, '2025-01-21'),
(6, 10000, '2025-01-21'),
(7, 50000, '2025-01-21'),
(8, 7000, '2025-01-21');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_kurir`
--

CREATE TABLE `tabel_kurir` (
  `id_kurir` int(11) NOT NULL,
  `nama_kurir` varchar(100) DEFAULT NULL,
  `plat_kendaraan` varchar(20) DEFAULT NULL,
  `id_cabang` int(11) DEFAULT NULL,
  `jenis_kendaraan` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_kurir`
--

INSERT INTO `tabel_kurir` (`id_kurir`, `nama_kurir`, `plat_kendaraan`, `id_cabang`, `jenis_kendaraan`) VALUES
(1, 'Budi', 'B 1234 XY', 1, 'Motor'),
(2, 'Budi', 'AB1234CD', 1, 'motor');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_laporan_transaksi`
--

CREATE TABLE `tabel_laporan_transaksi` (
  `id_laporan` int(11) NOT NULL,
  `tanggal` date DEFAULT NULL,
  `total_transaksi` int(11) DEFAULT NULL,
  `total_pembayaran` int(11) DEFAULT NULL,
  `total_pengiriman` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_laporan_transaksi`
--

INSERT INTO `tabel_laporan_transaksi` (`id_laporan`, `tanggal`, `total_transaksi`, `total_pembayaran`, `total_pengiriman`) VALUES
(4, '2025-01-20', 4, 117000, 7);

-- --------------------------------------------------------

--
-- Table structure for table `tabel_pelanggan`
--

CREATE TABLE `tabel_pelanggan` (
  `id_pelanggan` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `alamat` varchar(255) DEFAULT NULL,
  `nomor_telepon` varchar(20) DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `saldo` int(11) DEFAULT NULL,
  `limit_pinjam` int(11) DEFAULT NULL,
  `total_tunggakan` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_pelanggan`
--

INSERT INTO `tabel_pelanggan` (`id_pelanggan`, `nama`, `alamat`, `nomor_telepon`, `username`, `password`, `saldo`, `limit_pinjam`, `total_tunggakan`) VALUES
(1, 'John Doe', 'Jl. Merdeka No.10, Jakarta', '081234567890', 'johndoe', 'password123', 243000, 50000, 0);

-- --------------------------------------------------------

--
-- Table structure for table `tabel_penerima`
--

CREATE TABLE `tabel_penerima` (
  `id_penerima` int(11) NOT NULL,
  `nama_penerima` varchar(100) DEFAULT NULL,
  `alamat_penerima` varchar(255) DEFAULT NULL,
  `kontak_penerima` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_penerima`
--

INSERT INTO `tabel_penerima` (`id_penerima`, `nama_penerima`, `alamat_penerima`, `kontak_penerima`) VALUES
(6, 'Budi Santoso', 'Jl. Merdeka No. 10, Jakarta', '08123456789'),
(101, 'Budi Santoso', 'Jl. Merdeka No. 10, Jakarta', '08123456789'),
(102, 'Rudi Hartono', 'Jl. Sepuluh No. 15, Jakarta', '08123456789');

-- --------------------------------------------------------

--
-- Table structure for table `tabel_pengiriman`
--

CREATE TABLE `tabel_pengiriman` (
  `id_pengiriman` int(11) NOT NULL,
  `nomor_resi` varchar(50) DEFAULT NULL,
  `id_barang` int(11) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `tanggal_pengiriman` date DEFAULT NULL,
  `lokasi_asal` varchar(255) DEFAULT NULL,
  `lokasi_tujuan` varchar(255) DEFAULT NULL,
  `berat` int(11) DEFAULT NULL,
  `jumlah_paket` int(11) DEFAULT NULL,
  `biaya_pengiriman` int(11) DEFAULT NULL,
  `id_cs` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_pengiriman`
--

INSERT INTO `tabel_pengiriman` (`id_pengiriman`, `nomor_resi`, `id_barang`, `status`, `tanggal_pengiriman`, `lokasi_asal`, `lokasi_tujuan`, `berat`, `jumlah_paket`, `biaya_pengiriman`, `id_cs`) VALUES
(4, 'RESI-000004', NULL, 'Nyasar', '2025-01-20', 'Surabaya', 'Jakarta', 5, 3, 6500, 1),
(5, 'RESI-000005', 13, 'Terkirim', '2025-01-20', 'Surabaya', 'Jakarta', 5, 3, 6500, 1),
(6, 'RESI1737394858110', 14, 'Terkirim', '2025-01-21', 'Gudang Utama', 'Jakarta', 1, 1, 7000, 1);

-- --------------------------------------------------------

--
-- Table structure for table `tabel_transaksi`
--

CREATE TABLE `tabel_transaksi` (
  `id_transaksi` int(11) NOT NULL,
  `id_pelanggan` int(11) DEFAULT NULL,
  `jenis_transaksi` varchar(50) DEFAULT NULL,
  `jumlah` int(11) DEFAULT NULL,
  `tanggal_transaksi` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tabel_transaksi`
--

INSERT INTO `tabel_transaksi` (`id_transaksi`, `id_pelanggan`, `jenis_transaksi`, `jumlah`, `tanggal_transaksi`) VALUES
(5, 1, 'top-up saldo', 50000, '2025-01-21'),
(6, 1, 'pinjaman saldo', 10000, '2025-01-21'),
(7, 1, 'pembayaran tunggakan', 50000, '2025-01-21'),
(8, 1, 'pembayaran biaya pengiriman', 7000, '2025-01-21');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `barang_penerima`
--
ALTER TABLE `barang_penerima`
  ADD PRIMARY KEY (`id_barang`,`id_penerima`),
  ADD KEY `id_penerima` (`id_penerima`);

--
-- Indexes for table `tabel_admin`
--
ALTER TABLE `tabel_admin`
  ADD PRIMARY KEY (`id_admin`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `id_cabang` (`id_cabang`);

--
-- Indexes for table `tabel_barang`
--
ALTER TABLE `tabel_barang`
  ADD PRIMARY KEY (`id_barang`),
  ADD KEY `id_pengiriman` (`id_pengiriman`),
  ADD KEY `id_pelanggan` (`id_pelanggan`),
  ADD KEY `id_ekspedisi` (`id_ekspedisi`);

--
-- Indexes for table `tabel_cabang_ekspedisi`
--
ALTER TABLE `tabel_cabang_ekspedisi`
  ADD PRIMARY KEY (`id_cabang`),
  ADD KEY `id_ekspedisi` (`id_ekspedisi`);

--
-- Indexes for table `tabel_customer_service`
--
ALTER TABLE `tabel_customer_service`
  ADD PRIMARY KEY (`id_cs`),
  ADD KEY `fk_id_cabang` (`id_cabang`);

--
-- Indexes for table `tabel_ekspedisi`
--
ALTER TABLE `tabel_ekspedisi`
  ADD PRIMARY KEY (`id_ekspedisi`);

--
-- Indexes for table `tabel_keuangan`
--
ALTER TABLE `tabel_keuangan`
  ADD KEY `id_transaksi` (`id_transaksi`);

--
-- Indexes for table `tabel_kurir`
--
ALTER TABLE `tabel_kurir`
  ADD PRIMARY KEY (`id_kurir`),
  ADD KEY `id_cabang` (`id_cabang`);

--
-- Indexes for table `tabel_laporan_transaksi`
--
ALTER TABLE `tabel_laporan_transaksi`
  ADD PRIMARY KEY (`id_laporan`);

--
-- Indexes for table `tabel_pelanggan`
--
ALTER TABLE `tabel_pelanggan`
  ADD PRIMARY KEY (`id_pelanggan`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `tabel_penerima`
--
ALTER TABLE `tabel_penerima`
  ADD PRIMARY KEY (`id_penerima`);

--
-- Indexes for table `tabel_pengiriman`
--
ALTER TABLE `tabel_pengiriman`
  ADD PRIMARY KEY (`id_pengiriman`),
  ADD UNIQUE KEY `nomor_resi` (`nomor_resi`),
  ADD KEY `fk_barang` (`id_barang`),
  ADD KEY `id_cs` (`id_cs`);

--
-- Indexes for table `tabel_transaksi`
--
ALTER TABLE `tabel_transaksi`
  ADD PRIMARY KEY (`id_transaksi`),
  ADD KEY `id_pelanggan` (`id_pelanggan`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tabel_admin`
--
ALTER TABLE `tabel_admin`
  MODIFY `id_admin` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tabel_barang`
--
ALTER TABLE `tabel_barang`
  MODIFY `id_barang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `tabel_cabang_ekspedisi`
--
ALTER TABLE `tabel_cabang_ekspedisi`
  MODIFY `id_cabang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tabel_customer_service`
--
ALTER TABLE `tabel_customer_service`
  MODIFY `id_cs` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tabel_ekspedisi`
--
ALTER TABLE `tabel_ekspedisi`
  MODIFY `id_ekspedisi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tabel_kurir`
--
ALTER TABLE `tabel_kurir`
  MODIFY `id_kurir` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tabel_laporan_transaksi`
--
ALTER TABLE `tabel_laporan_transaksi`
  MODIFY `id_laporan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `tabel_pelanggan`
--
ALTER TABLE `tabel_pelanggan`
  MODIFY `id_pelanggan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tabel_penerima`
--
ALTER TABLE `tabel_penerima`
  MODIFY `id_penerima` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT for table `tabel_pengiriman`
--
ALTER TABLE `tabel_pengiriman`
  MODIFY `id_pengiriman` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `tabel_transaksi`
--
ALTER TABLE `tabel_transaksi`
  MODIFY `id_transaksi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `barang_penerima`
--
ALTER TABLE `barang_penerima`
  ADD CONSTRAINT `barang_penerima_ibfk_1` FOREIGN KEY (`id_barang`) REFERENCES `tabel_barang` (`id_barang`),
  ADD CONSTRAINT `barang_penerima_ibfk_2` FOREIGN KEY (`id_penerima`) REFERENCES `tabel_penerima` (`id_penerima`);

--
-- Constraints for table `tabel_admin`
--
ALTER TABLE `tabel_admin`
  ADD CONSTRAINT `tabel_admin_ibfk_1` FOREIGN KEY (`id_cabang`) REFERENCES `tabel_cabang_ekspedisi` (`id_cabang`);

--
-- Constraints for table `tabel_barang`
--
ALTER TABLE `tabel_barang`
  ADD CONSTRAINT `tabel_barang_ibfk_1` FOREIGN KEY (`id_pengiriman`) REFERENCES `tabel_pengiriman` (`id_pengiriman`),
  ADD CONSTRAINT `tabel_barang_ibfk_2` FOREIGN KEY (`id_pelanggan`) REFERENCES `tabel_pelanggan` (`id_pelanggan`),
  ADD CONSTRAINT `tabel_barang_ibfk_3` FOREIGN KEY (`id_ekspedisi`) REFERENCES `tabel_ekspedisi` (`id_ekspedisi`);

--
-- Constraints for table `tabel_cabang_ekspedisi`
--
ALTER TABLE `tabel_cabang_ekspedisi`
  ADD CONSTRAINT `tabel_cabang_ekspedisi_ibfk_1` FOREIGN KEY (`id_ekspedisi`) REFERENCES `tabel_ekspedisi` (`id_ekspedisi`);

--
-- Constraints for table `tabel_customer_service`
--
ALTER TABLE `tabel_customer_service`
  ADD CONSTRAINT `fk_id_cabang` FOREIGN KEY (`id_cabang`) REFERENCES `tabel_cabang_ekspedisi` (`id_cabang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `tabel_customer_service_ibfk_1` FOREIGN KEY (`id_cabang`) REFERENCES `tabel_cabang_ekspedisi` (`id_cabang`),
  ADD CONSTRAINT `tabel_customer_service_ibfk_2` FOREIGN KEY (`id_cabang`) REFERENCES `tabel_cabang_ekspedisi` (`id_cabang`);

--
-- Constraints for table `tabel_keuangan`
--
ALTER TABLE `tabel_keuangan`
  ADD CONSTRAINT `tabel_keuangan_ibfk_1` FOREIGN KEY (`id_transaksi`) REFERENCES `tabel_transaksi` (`id_transaksi`);

--
-- Constraints for table `tabel_kurir`
--
ALTER TABLE `tabel_kurir`
  ADD CONSTRAINT `tabel_kurir_ibfk_1` FOREIGN KEY (`id_cabang`) REFERENCES `tabel_cabang_ekspedisi` (`id_cabang`);

--
-- Constraints for table `tabel_pengiriman`
--
ALTER TABLE `tabel_pengiriman`
  ADD CONSTRAINT `fk_barang` FOREIGN KEY (`id_barang`) REFERENCES `tabel_barang` (`id_barang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `tabel_pengiriman_ibfk_1` FOREIGN KEY (`id_barang`) REFERENCES `tabel_barang` (`id_barang`),
  ADD CONSTRAINT `tabel_pengiriman_ibfk_2` FOREIGN KEY (`id_barang`) REFERENCES `tabel_barang` (`id_barang`),
  ADD CONSTRAINT `tabel_pengiriman_ibfk_3` FOREIGN KEY (`id_cs`) REFERENCES `tabel_customer_service` (`id_cs`);

--
-- Constraints for table `tabel_transaksi`
--
ALTER TABLE `tabel_transaksi`
  ADD CONSTRAINT `tabel_transaksi_ibfk_1` FOREIGN KEY (`id_pelanggan`) REFERENCES `tabel_pelanggan` (`id_pelanggan`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
