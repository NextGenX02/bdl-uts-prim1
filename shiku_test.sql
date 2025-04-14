-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 14, 2025 at 02:16 PM
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
-- Database: `shiku_test`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`shiku`@`%` PROCEDURE `EditPresensi` (IN `pre_id_presensi` INT, IN `pre_metode_presensi` VARCHAR(50), IN `pre_waktu_presensi` TIME)   BEGIN
    DECLARE waktu_mulai TIME;
    DECLARE waktu_batas_terlambat TIME;
    DECLARE id_sesiKuliah INT;
    DECLARE status_hadir VARCHAR(20);

    -- Ambil sesi presensi
    SELECT id_sesi INTO id_sesiKuliah
    FROM presensi
    WHERE id_presensi = pre_id_presensi;

    -- Ambil waktu mulai sesi
    SELECT tanggal_waktu_mulai INTO waktu_mulai
    FROM sesi_perkuliahan
    WHERE id_sesi = id_sesiKuliah;

    -- Hitung batas terlambat
    SET waktu_batas_terlambat = TIME(DATE_ADD(waktu_mulai, INTERVAL 30 MINUTE));

    -- Tentukan status baru
    IF pre_waktu_presensi <= waktu_batas_terlambat THEN
        SET status_hadir = 'Hadir';
    ELSE
        SET status_hadir = 'Terlambat';
    END IF;

    -- Update presensi
    UPDATE presensi
    SET metode_presensi = pre_metode_presensi,
        waktu_presensi = pre_waktu_presensi,
        status_kehadiran = status_hadir
    WHERE id_presensi = pre_id_presensi;
END$$

CREATE DEFINER=`shiku`@`%` PROCEDURE `HapusPresensi` (IN `pre_id_presensi` INT)   BEGIN
        DELETE FROM presensi WHERE id_presensi = pre_id_presensi;
    end$$

CREATE DEFINER=`shiku`@`%` PROCEDURE `RekapPresensiKelas` (IN `pre_id_kelas` INT)   BEGIN
    SELECT m.id_mahasiswa, m.nama AS nama_mahasiswa,
           COUNT(CASE WHEN p.status_kehadiran = 'Hadir' THEN 1 END) AS jumlah_hadir,
           COUNT(CASE WHEN p.status_kehadiran = 'Terlambat' THEN 1 END) AS jumlah_terlambat,
           COUNT(CASE WHEN p.status_kehadiran = 'Alpha' THEN 1 END) AS jumlah_alpha
        FROM mahasiswa m join terdaftar t ON m.id_mahasiswa = t.id_mahasiswa
    JOIN kelas k ON t.id_kelas = k.id_kelas JOIN sesi_perkuliahan s ON k.id_kelas = s.id_kelas
    LEFT JOIN presensi p ON m.id_mahasiswa = p.id_mahasiswa and p.id_sesi = s.id_sesi WHERE k.id_kelas = pre_id_kelas GROUP BY m.id_mahasiswa, m.nama ;
end$$

CREATE DEFINER=`shiku`@`%` PROCEDURE `TambahAbsensi` (IN `pre_id_sesi` INT, IN `pre_id_mahasiswa` INT, IN `pre_metode_absensi` VARCHAR(50), IN `pre_waktu_absen` TIME)   begin
    declare waktu_mulai TIME;
    declare waktu_batas_terlambat TIME;
    declare status_hadir varchar(20);

    SELECT sesi_perkuliahan.tanggal_waktu_mulai INTO waktu_mulai FROM sesi_perkuliahan where id_sesi = pre_id_sesi;

    -- Batas terlammbat
    SET waktu_batas_terlambat = TIME(DATE_ADD(waktu_mulai, INTERVAL 30 MINUTE));

    -- Status Kehadiran
    IF pre_waktu_absen <= waktu_batas_terlambat THEN
        SET status_hadir = 'Hadir';
    ELSE
        SET status_hadir = 'Terlambat';
    END if;

    -- simpan
    INSERT INTO presensi (id_sesi, id_mahasiswa, metode_presensi, waktu_presensi, status_kehadiran)
    values (pre_id_sesi, pre_id_mahasiswa, pre_metode_absensi, pre_waktu_absen, status_hadir);
end$$

--
-- Functions
--
CREATE DEFINER=`shiku`@`%` FUNCTION `CekAbsensi` (`id_sesiAbsen` INT, `id_siswa` INT) RETURNS TINYINT(1) DETERMINISTIC begin
    declare sudah_absen BOOLEAN;
    select exists(
        select 1 from presensi where presensi.id_sesi = id_sesiAbsen and presensi.id_mahasiswa = id_siswa
    ) into sudah_absen;
    return sudah_absen;
end$$

CREATE DEFINER=`shiku`@`%` FUNCTION `HitungPresensiKelas` (`pre_id_mahasiswa` INT, `pre_id_kelas` INT, `pre_status` VARCHAR(20)) RETURNS INT(11) DETERMINISTIC begin
    DECLARE jumlah INT;

    SELECT count(p.id_presensi) INTO jumlah FROM presensi p JOIN sesi_perkuliahan s ON p.id_sesi = s.id_sesi
    WHERE p.id_mahasiswa = pre_id_mahasiswa AND s.id_kelas = pre_id_kelas AND p.status_kehadiran = pre_status;

    RETURN jumlah;
end$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `dosen`
--

CREATE TABLE `dosen` (
  `id_dosen` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `NIP` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `dosen`
--

INSERT INTO `dosen` (`id_dosen`, `nama`, `NIP`, `email`) VALUES
(1, 'Dr.Yogi Regestrawan', '9932188412312311', 'dummy@shiku.net'),
(2, 'I Wayan Wahyu Surya Putra S.Kom, M.Kom', '88832432423423', 'dummy@shiku.net'),
(3, 'I Putu Danusucita', '12929144553', 'dummy@shiku.net');

-- --------------------------------------------------------

--
-- Table structure for table `kelas`
--

CREATE TABLE `kelas` (
  `id_kelas` int(11) NOT NULL,
  `nama_kelas` varchar(100) DEFAULT NULL,
  `id_dosen` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `kelas`
--

INSERT INTO `kelas` (`id_kelas`, `nama_kelas`, `id_dosen`) VALUES
(1, 'fotographi', 1),
(2, 'peselarasan gender', 2),
(3, 'AI Super', 3);

-- --------------------------------------------------------

--
-- Table structure for table `mahasiswa`
--

CREATE TABLE `mahasiswa` (
  `id_mahasiswa` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `NIM` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `foto_profile` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mahasiswa`
--

INSERT INTO `mahasiswa` (`id_mahasiswa`, `nama`, `NIM`, `email`, `foto_profile`) VALUES
(1, 'Iqbal Maulana', '434234234255', 'dummy@shiku.net', 'igbal.jpg'),
(2, 'Budi Santoso', '202201001', 'budi.santoso@student.univ.ac.id', 'budi.jpg'),
(3, 'Rina Lestari', '202201002', 'rina.lestari@student.univ.ac.id', 'rina.jpg'),
(4, 'Deni Pratama', '202201003', 'deni.pratama@student.univ.ac.id', 'deni.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `presensi`
--

CREATE TABLE `presensi` (
  `id_presensi` int(11) NOT NULL,
  `id_sesi` int(11) DEFAULT NULL,
  `id_mahasiswa` int(11) DEFAULT NULL,
  `metode_presensi` varchar(50) DEFAULT NULL,
  `waktu_presensi` datetime DEFAULT NULL,
  `status_kehadiran` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `presensi`
--

INSERT INTO `presensi` (`id_presensi`, `id_sesi`, `id_mahasiswa`, `metode_presensi`, `waktu_presensi`, `status_kehadiran`) VALUES
(1, 1, 1, 'offline', '2025-04-14 08:35:00', 'Hadir'),
(3, 3, 2, 'Offline', '2025-04-14 09:44:00', 'Hadir'),
(4, 3, 3, 'Online', '2025-04-14 09:35:00', 'Hadir'),
(5, 2, 1, 'Online', '2025-04-14 10:32:00', 'Hadir'),
(6, 2, 1, 'Online', '2025-04-14 10:40:31', 'Hadir'),
(7, 2, 3, 'Offline', '2025-04-14 10:53:34', 'Hadir'),
(8, 1, 1, 'Offline', '2025-04-14 09:28:00', 'Terlambat'),
(9, 1, 3, 'Offline', '2025-04-14 08:59:33', 'Hadir'),
(10, 2, 1, 'Offline', '2025-04-14 11:19:20', 'Terlambat'),
(11, 1, 2, 'Online', '2025-04-14 08:34:44', 'Hadir'),
(12, 3, 2, 'Online', '2025-04-14 10:14:31', 'Terlambat'),
(13, 2, 1, 'Offline', '2025-04-14 11:24:15', 'Terlambat'),
(14, 2, 2, 'Online', '2025-04-14 11:07:47', 'Terlambat'),
(15, 1, 1, 'Online', '2025-04-14 09:18:15', 'Terlambat'),
(16, 2, 4, 'Online', '2025-04-14 10:42:28', 'Hadir'),
(17, 2, 3, 'Online', '2025-04-14 10:43:10', 'Hadir'),
(18, 2, 1, 'Online', '2025-04-14 10:46:02', 'Hadir'),
(19, 1, 2, 'Offline', '2025-04-14 09:09:14', 'Terlambat'),
(20, 2, 2, 'Online', '2025-04-14 11:09:53', 'Terlambat'),
(21, 1, 3, 'Offline', '2025-04-14 08:35:03', 'Hadir'),
(22, 3, 2, 'Online', '2025-04-14 10:08:16', 'Terlambat');

-- --------------------------------------------------------

--
-- Table structure for table `sesi_perkuliahan`
--

CREATE TABLE `sesi_perkuliahan` (
  `id_sesi` int(11) NOT NULL,
  `id_kelas` int(11) DEFAULT NULL,
  `tanggal_waktu_mulai` time DEFAULT NULL,
  `tanggal_waktu_selesai` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sesi_perkuliahan`
--

INSERT INTO `sesi_perkuliahan` (`id_sesi`, `id_kelas`, `tanggal_waktu_mulai`, `tanggal_waktu_selesai`) VALUES
(1, 1, '08:30:00', '09:30:00'),
(2, 2, '10:30:00', '11:30:00'),
(3, 3, '09:30:00', '10:30:00');

-- --------------------------------------------------------

--
-- Table structure for table `terdaftar`
--

CREATE TABLE `terdaftar` (
  `id_kelas` int(11) NOT NULL,
  `id_mahasiswa` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `terdaftar`
--

INSERT INTO `terdaftar` (`id_kelas`, `id_mahasiswa`) VALUES
(1, 1),
(1, 2),
(1, 4),
(2, 1),
(2, 2),
(2, 3),
(3, 1),
(3, 2),
(3, 3);

-- --------------------------------------------------------

--
-- Stand-in structure for view `viewabsensifull`
-- (See below for the actual view)
--
CREATE TABLE `viewabsensifull` (
`id_presensi` int(11)
,`id_mahasiswa` int(11)
,`nama_mahasiswa` varchar(100)
,`id_kelas` int(11)
,`nama_kelas` varchar(100)
,`nama_dosen` varchar(100)
,`tanggal_waktu_mulai` time
,`metode_presensi` varchar(50)
,`status_kehadiran` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `viewrekappresensi`
-- (See below for the actual view)
--
CREATE TABLE `viewrekappresensi` (
`id_kelas` int(11)
,`nama_kelas` varchar(100)
,`id_mahasiswa` int(11)
,`nama_mahasiswa` varchar(100)
,`jumlah_hadir` bigint(21)
,`jumlah_terlambat` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure for view `viewabsensifull`
--
DROP TABLE IF EXISTS `viewabsensifull`;

CREATE ALGORITHM=UNDEFINED DEFINER=`shiku`@`%` SQL SECURITY DEFINER VIEW `viewabsensifull`  AS SELECT `p`.`id_presensi` AS `id_presensi`, `m`.`id_mahasiswa` AS `id_mahasiswa`, `m`.`nama` AS `nama_mahasiswa`, `k`.`id_kelas` AS `id_kelas`, `k`.`nama_kelas` AS `nama_kelas`, `d`.`nama` AS `nama_dosen`, `s`.`tanggal_waktu_mulai` AS `tanggal_waktu_mulai`, `p`.`metode_presensi` AS `metode_presensi`, `p`.`status_kehadiran` AS `status_kehadiran` FROM ((((`presensi` `p` join `mahasiswa` `m` on(`p`.`id_mahasiswa` = `m`.`id_mahasiswa`)) join `sesi_perkuliahan` `s` on(`p`.`id_sesi` = `s`.`id_sesi`)) join `kelas` `k` on(`s`.`id_kelas` = `k`.`id_kelas`)) join `dosen` `d` on(`k`.`id_dosen` = `d`.`id_dosen`)) ;

-- --------------------------------------------------------

--
-- Structure for view `viewrekappresensi`
--
DROP TABLE IF EXISTS `viewrekappresensi`;

CREATE ALGORITHM=UNDEFINED DEFINER=`shiku`@`%` SQL SECURITY DEFINER VIEW `viewrekappresensi`  AS SELECT `k`.`id_kelas` AS `id_kelas`, `k`.`nama_kelas` AS `nama_kelas`, `m`.`id_mahasiswa` AS `id_mahasiswa`, `m`.`nama` AS `nama_mahasiswa`, count(case when `p`.`status_kehadiran` = 'Hadir' then 1 end) AS `jumlah_hadir`, count(case when `p`.`status_kehadiran` = 'Terlambat' then 1 end) AS `jumlah_terlambat` FROM ((((`mahasiswa` `m` join `terdaftar` `t` on(`m`.`id_mahasiswa` = `t`.`id_mahasiswa`)) join `kelas` `k` on(`t`.`id_kelas` = `k`.`id_kelas`)) join `sesi_perkuliahan` `s` on(`k`.`id_kelas` = `s`.`id_kelas`)) left join `presensi` `p` on(`m`.`id_mahasiswa` = `p`.`id_mahasiswa` and `p`.`id_sesi` = `s`.`id_sesi`)) GROUP BY `k`.`id_kelas`, `k`.`nama_kelas`, `m`.`id_mahasiswa`, `m`.`nama` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `dosen`
--
ALTER TABLE `dosen`
  ADD PRIMARY KEY (`id_dosen`);

--
-- Indexes for table `kelas`
--
ALTER TABLE `kelas`
  ADD PRIMARY KEY (`id_kelas`),
  ADD KEY `id_dosen` (`id_dosen`);

--
-- Indexes for table `mahasiswa`
--
ALTER TABLE `mahasiswa`
  ADD PRIMARY KEY (`id_mahasiswa`);

--
-- Indexes for table `presensi`
--
ALTER TABLE `presensi`
  ADD PRIMARY KEY (`id_presensi`),
  ADD KEY `id_sesi` (`id_sesi`),
  ADD KEY `id_mahasiswa` (`id_mahasiswa`);

--
-- Indexes for table `sesi_perkuliahan`
--
ALTER TABLE `sesi_perkuliahan`
  ADD PRIMARY KEY (`id_sesi`),
  ADD KEY `id_kelas` (`id_kelas`);

--
-- Indexes for table `terdaftar`
--
ALTER TABLE `terdaftar`
  ADD PRIMARY KEY (`id_kelas`,`id_mahasiswa`),
  ADD KEY `id_mahasiswa` (`id_mahasiswa`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `dosen`
--
ALTER TABLE `dosen`
  MODIFY `id_dosen` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `kelas`
--
ALTER TABLE `kelas`
  MODIFY `id_kelas` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `mahasiswa`
--
ALTER TABLE `mahasiswa`
  MODIFY `id_mahasiswa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `presensi`
--
ALTER TABLE `presensi`
  MODIFY `id_presensi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `sesi_perkuliahan`
--
ALTER TABLE `sesi_perkuliahan`
  MODIFY `id_sesi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `kelas`
--
ALTER TABLE `kelas`
  ADD CONSTRAINT `kelas_ibfk_1` FOREIGN KEY (`id_dosen`) REFERENCES `dosen` (`id_dosen`);

--
-- Constraints for table `presensi`
--
ALTER TABLE `presensi`
  ADD CONSTRAINT `presensi_ibfk_1` FOREIGN KEY (`id_sesi`) REFERENCES `sesi_perkuliahan` (`id_sesi`),
  ADD CONSTRAINT `presensi_ibfk_2` FOREIGN KEY (`id_mahasiswa`) REFERENCES `mahasiswa` (`id_mahasiswa`);

--
-- Constraints for table `sesi_perkuliahan`
--
ALTER TABLE `sesi_perkuliahan`
  ADD CONSTRAINT `sesi_perkuliahan_ibfk_1` FOREIGN KEY (`id_kelas`) REFERENCES `kelas` (`id_kelas`);

--
-- Constraints for table `terdaftar`
--
ALTER TABLE `terdaftar`
  ADD CONSTRAINT `terdaftar_ibfk_1` FOREIGN KEY (`id_kelas`) REFERENCES `kelas` (`id_kelas`),
  ADD CONSTRAINT `terdaftar_ibfk_2` FOREIGN KEY (`id_mahasiswa`) REFERENCES `mahasiswa` (`id_mahasiswa`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
