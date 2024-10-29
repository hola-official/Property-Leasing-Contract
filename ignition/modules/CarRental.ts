// scripts/deploy-car-rental.js

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";

const CarRentalModule = buildModule("CarRentalModule", (m) => {
  const rentalAmount = m.getParameter(
    "rentalAmount",
    ethers.parseEther("10")
  );
  const securityDeposit = m.getParameter(
    "securityDeposit",
    ethers.parseEther("100")
  );
  const rentalDuration = m.getParameter("rentalDuration", 86400);
  const paymentFrequency = m.getParameter("paymentFrequency", 3600);

  const carRental = m.contract("CarRental", [
    rentalAmount,
    securityDeposit,
    rentalDuration,
    paymentFrequency,
  ]);

  return { carRental };
});

export default CarRentalModule;
