-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Nov 22, 2023 at 04:45 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.0.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `flickseats`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CalculateWallet` (IN `customerId` INT, OUT `wallet_money` INT)   BEGIN
    DECLARE money INT DEFAULT 0;
    SELECT Wallet INTO money FROM Customers WHERE id = customerId;
    SET wallet_money = money;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CalculateTotalRevenue` (`theaterName` VARCHAR(255)) RETURNS INT(11)  BEGIN
    DECLARE totalRevenue INT;

    SELECT SUM(Payment) INTO totalRevenue
    FROM bookings
    WHERE Name = theaterName;

    RETURN totalRevenue;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `Bid` int(11) NOT NULL,
  `Title` varchar(200) NOT NULL,
  `Name` varchar(200) NOT NULL,
  `ScreenNumber` int(11) NOT NULL,
  `SeatNumber` int(11) NOT NULL,
  `Date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `Payment` int(11) NOT NULL,
  `CustomerID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`Bid`, `Title`, `Name`, `ScreenNumber`, `SeatNumber`, `Date`, `Payment`, `CustomerID`) VALUES
(15, 'The Dark Knight', 'City Cinemas', 1, 2, '2023-11-14 08:47:01', 100, 2),
(16, 'The Dark Knight', 'Star Movies', 2, 6, '2023-11-14 12:05:02', 100, 5),
(17, 'Pulp Fiction', 'Star Movies', 0, 0, '2023-11-14 08:47:15', 100, 4),
(18, 'The Shawshank Redemption', 'CinemaPlex', 2, 4, '2023-11-14 08:47:19', 100, 3),
(20, 'Pulp Fiction', 'Star Movies', 3, 6, '2023-11-14 08:47:26', 100, 6),
(21, 'The Dark Knight', 'Star Movies', 3, 3, '2023-11-14 08:47:30', 100, 7),
(22, 'The Shawshank Redemption', 'Mega Cineworld', 3, 3, '2023-11-14 08:47:33', 300, 7),
(23, 'Pulp Fiction', 'CinemaPlex', 1, 6, '2023-11-14 08:47:36', 100, 7),
(32, 'The Shawshank Redemption', 'CinemaPlex', 1, 3, '2023-11-14 12:21:22', 100, 7),
(33, 'The Dark Knight', 'Star Movies', 1, 4, '2023-11-14 12:44:48', 100, 7),
(34, 'Pulp Fiction', 'Mega Cineworld', 3, 3, '2023-11-14 12:55:42', 300, 7),
(35, 'The Shawshank Redemption', 'Royal Theaters', 2, 9, '2023-11-14 14:28:24', 200, 7),
(36, 'Pulp Fiction', 'City Cinemas', 3, 5, '2023-11-14 15:12:41', 300, 7),
(37, 'The Shawshank Redemption', 'Mega Cineworld', 1, 4, '2023-11-16 05:25:13', 100, 6);

--
-- Triggers `bookings`
--
DELIMITER $$
CREATE TRIGGER `payment` AFTER INSERT ON `bookings` FOR EACH ROW BEGIN
    -- Declare variables
    DECLARE booking_amount INT;
    DECLARE user_id INT;
    DECLARE Discount INT;

    -- Retrieve values
    SELECT Payment, CustomerID INTO booking_amount, user_id FROM bookings WHERE Bid = NEW.Bid;

    -- Check if Discount exists for the theater
    SELECT Discount INTO Discount FROM theaters WHERE Name = NEW.Name LIMIT 1;

    IF Discount IS NULL THEN
        SET Discount = 0;
    END IF;

    -- Update customer wallet
    UPDATE customers SET wallet = wallet - booking_amount * (1 - Discount / 100) WHERE id = user_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `refund` BEFORE DELETE ON `bookings` FOR EACH ROW BEGIN
    -- Declare variables
    DECLARE booking_amount INT;
    DECLARE user_id INT;
    DECLARE Discount INT;

    -- Retrieve values from the row being deleted
    SELECT Payment, CustomerID INTO booking_amount, user_id FROM bookings WHERE Bid = OLD.Bid;
    
    -- Check if Discount exists for the theater
    SELECT Discount INTO Discount FROM theaters WHERE Name = OLD.Name LIMIT 1;

    -- Handle the case where Discount is NULL
    IF Discount IS NULL THEN
        SET Discount = 0; -- Set a default value or handle it as needed
    END IF;
    -- Update customer wallet
    UPDATE customers SET wallet = wallet + booking_amount*(1-Discount/100) WHERE id = user_id;

    -- Insert into refund table
    INSERT INTO refund VALUES(null, OLD.Bid, booking_amount);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` int(11) NOT NULL,
  `FirstName` varchar(50) NOT NULL,
  `LastName` varchar(50) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `Phone` varchar(15) DEFAULT NULL,
  `Password` varchar(1000) NOT NULL,
  `Wallet` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`id`, `FirstName`, `LastName`, `Email`, `Phone`, `Password`, `Wallet`) VALUES
(1, 'Alice', 'Johnson', 'alice@example.com', '555-111-2222', 'alice', 1100),
(2, 'Bob', 'Smith', 'bob@example.com', '555-222-3333', 'bob', 1000),
(3, 'Charlie', 'Brown', 'charlie@example.com', '555-333-4444', 'charlie', 1000),
(4, 'David', 'Lee', 'david@example.com', '555-444-5555', 'david', 500),
(5, 'Eve', 'Wilson', 'eve@example.com', '555-555-6666', 'eve', 400),
(6, 'pal', 'mon', 'palmon@mail', '1231231341221', 'scrypt:32768:8:1$lune84QSugaxTdLP$bb4f4f325627fd00c26005987a36cccfd58d6437c28b72aab1e512091b3c507e54a022a3b0bc295ee3a056f3c853b23fddaef621e6d104a7fe7426a55c1098ee', 500),
(7, 'lim', 'dim', 'limdim@mail', '5544332211', 'scrypt:32768:8:1$8OjjtJVHlyzY3XEe$441cee8b2f61d0685a9094f5648c5cf87aa18f5b2e7c19211697cda1b24b822ef4f01d80a5db121e22e3844ce1e249327c1419550ed4a0a6f02d50135b193232', 1000);

-- --------------------------------------------------------

--
-- Table structure for table `movies`
--

CREATE TABLE `movies` (
  `MovieID` int(11) NOT NULL,
  `Title` varchar(255) NOT NULL,
  `Genre` varchar(100) DEFAULT NULL,
  `ReleaseDate` date DEFAULT NULL,
  `Director` varchar(100) DEFAULT NULL,
  `Description` text DEFAULT NULL,
  `Rating` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `movies`
--

INSERT INTO `movies` (`MovieID`, `Title`, `Genre`, `ReleaseDate`, `Director`, `Description`, `Rating`) VALUES
(1, 'The Shawshank Redemption', 'Drama', '1994-09-10', 'Frank Darabont', 'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.', 3),
(2, 'The Godfather', 'Crime', '1972-03-15', 'Francis Ford Coppola', 'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.', 5),
(3, 'The Dark Knight', 'Action', '2008-07-18', 'Christopher Nolan', 'When the menace known as The Joker emerges from his mysterious past, he wreaks havoc and chaos on the people of Gotham.', 4),
(4, 'Pulp Fiction', 'Crime', '1994-10-14', 'Quentin Tarantino', 'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.', 3),
(5, 'Inception', 'Sci-Fi', '2010-07-16', 'Christopher Nolan', 'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.', 5);

-- --------------------------------------------------------

--
-- Table structure for table `refund`
--

CREATE TABLE `refund` (
  `rid` int(11) NOT NULL,
  `Bid` int(11) NOT NULL,
  `Payment` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `refund`
--

INSERT INTO `refund` (`rid`, `Bid`, `Payment`) VALUES
(1, 31, 300),
(2, 8, 0),
(3, 30, 200),
(4, 19, 100),
(5, 4, 0),
(6, 5, 0),
(7, 6, 0),
(8, 7, 0),
(9, 38, 200);

-- --------------------------------------------------------

--
-- Table structure for table `screens`
--

CREATE TABLE `screens` (
  `TheaterID` int(11) NOT NULL,
  `ScreenNumber` int(11) NOT NULL,
  `SeatNumber` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `screens`
--

INSERT INTO `screens` (`TheaterID`, `ScreenNumber`, `SeatNumber`) VALUES
(1, 1, 1),
(1, 1, 2),
(1, 1, 3),
(1, 1, 4),
(1, 1, 5),
(1, 1, 6),
(1, 1, 7),
(1, 1, 8),
(1, 1, 9),
(1, 1, 10),
(1, 2, 1),
(1, 2, 2),
(1, 2, 3),
(1, 2, 4),
(1, 2, 5),
(1, 2, 6),
(1, 2, 7),
(1, 2, 8),
(1, 2, 9),
(1, 2, 10),
(1, 3, 1),
(1, 3, 2),
(1, 3, 3),
(1, 3, 4),
(1, 3, 5),
(1, 3, 6),
(1, 3, 7),
(1, 3, 8),
(1, 3, 9),
(1, 3, 10),
(2, 1, 1),
(2, 1, 2),
(2, 1, 3),
(2, 1, 4),
(2, 1, 5),
(2, 1, 6),
(2, 1, 7),
(2, 1, 8),
(2, 1, 9),
(2, 1, 10),
(2, 2, 1),
(2, 2, 2),
(2, 2, 3),
(2, 2, 4),
(2, 2, 5),
(2, 2, 6),
(2, 2, 7),
(2, 2, 8),
(2, 2, 9),
(2, 2, 10),
(2, 3, 1),
(2, 3, 2),
(2, 3, 3),
(2, 3, 4),
(2, 3, 5),
(2, 3, 6),
(2, 3, 7),
(2, 3, 8),
(2, 3, 9),
(2, 3, 10),
(3, 1, 1),
(3, 1, 2),
(3, 1, 3),
(3, 1, 4),
(3, 1, 5),
(3, 1, 6),
(3, 1, 7),
(3, 1, 8),
(3, 1, 9),
(3, 1, 10),
(3, 2, 1),
(3, 2, 2),
(3, 2, 3),
(3, 2, 4),
(3, 2, 5),
(3, 2, 6),
(3, 2, 7),
(3, 2, 8),
(3, 2, 9),
(3, 2, 10),
(3, 3, 1),
(3, 3, 2),
(3, 3, 3),
(3, 3, 4),
(3, 3, 5),
(3, 3, 6),
(3, 3, 7),
(3, 3, 8),
(3, 3, 9),
(3, 3, 10),
(4, 1, 1),
(4, 1, 2),
(4, 1, 3),
(4, 1, 4),
(4, 1, 5),
(4, 1, 6),
(4, 1, 7),
(4, 1, 8),
(4, 1, 9),
(4, 1, 10),
(4, 2, 1),
(4, 2, 2),
(4, 2, 3),
(4, 2, 4),
(4, 2, 5),
(4, 2, 6),
(4, 2, 7),
(4, 2, 8),
(4, 2, 9),
(4, 2, 10),
(4, 3, 1),
(4, 3, 2),
(4, 3, 3),
(4, 3, 4),
(4, 3, 5),
(4, 3, 6),
(4, 3, 7),
(4, 3, 8),
(4, 3, 9),
(4, 3, 10),
(5, 1, 1),
(5, 1, 2),
(5, 1, 3),
(5, 1, 4),
(5, 1, 5),
(5, 1, 6),
(5, 1, 7),
(5, 1, 8),
(5, 1, 9),
(5, 1, 10),
(5, 2, 1),
(5, 2, 2),
(5, 2, 3),
(5, 2, 4),
(5, 2, 5),
(5, 2, 6),
(5, 2, 7),
(5, 2, 8),
(5, 2, 9),
(5, 2, 10),
(5, 3, 1),
(5, 3, 2),
(5, 3, 3),
(5, 3, 4),
(5, 3, 5),
(5, 3, 6),
(5, 3, 7),
(5, 3, 8),
(5, 3, 9),
(5, 3, 10);

-- --------------------------------------------------------

--
-- Table structure for table `theaters`
--

CREATE TABLE `theaters` (
  `TheaterID` int(11) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Location` varchar(255) NOT NULL,
  `Discount` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `theaters`
--

INSERT INTO `theaters` (`TheaterID`, `Name`, `Location`, `Discount`) VALUES
(1, 'CinemaPlex', '123 Main Street', 10),
(2, 'City Cinemas', '456 Elm Avenue', 15),
(3, 'Star Movies', '789 Oak Lane', 5),
(4, 'Mega Cineworld', '101 Pine Road', 10),
(5, 'Royal Theaters', '222 Cedar Street', 10);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`Bid`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `Email` (`Email`);

--
-- Indexes for table `movies`
--
ALTER TABLE `movies`
  ADD PRIMARY KEY (`MovieID`),
  ADD UNIQUE KEY `Title` (`Title`);

--
-- Indexes for table `refund`
--
ALTER TABLE `refund`
  ADD PRIMARY KEY (`rid`);

--
-- Indexes for table `screens`
--
ALTER TABLE `screens`
  ADD PRIMARY KEY (`TheaterID`,`ScreenNumber`,`SeatNumber`);

--
-- Indexes for table `theaters`
--
ALTER TABLE `theaters`
  ADD PRIMARY KEY (`TheaterID`),
  ADD UNIQUE KEY `Name` (`Name`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `Bid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `movies`
--
ALTER TABLE `movies`
  MODIFY `MovieID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `refund`
--
ALTER TABLE `refund`
  MODIFY `rid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `theaters`
--
ALTER TABLE `theaters`
  MODIFY `TheaterID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
