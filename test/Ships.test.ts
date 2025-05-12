import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther } from "viem";

describe("Ships", function () {
  // Deploy function to set up the initial state
  async function deployShipsFixture() {
    const [owner, user1, user2] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy mock contracts first
    const mockShipNames = await hre.viem.deployContract(
      "MockOnchainRandomShipNames"
    );
    const mockRenderer = await hre.viem.deployContract("MockRenderer");

    // Deploy the RandomManager contract
    const randomManager = await hre.viem.deployContract("RandomManager");

    // Deploy the Ships contract
    const ships = await hre.viem.deployContract("Ships", [
      mockShipNames.address,
      mockRenderer.address,
    ]);

    // Set the random manager
    await ships.write.setRandomManager([randomManager.address]);

    return {
      ships,
      mockShipNames,
      mockRenderer,
      randomManager,
      owner,
      user1,
      user2,
      publicClient,
    };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { ships, owner } = await loadFixture(deployShipsFixture);
      const contractOwner = await ships.read.owner();
      expect(contractOwner.toLowerCase()).to.equal(
        owner.account.address.toLowerCase()
      );
    });

    it("Should set the correct initial ship price", async function () {
      const { ships } = await loadFixture(deployShipsFixture);
      const price = await ships.read.shipPrice();
      expect(price).to.equal(parseEther("1"));
    });
  });

  describe("Minting", function () {
    it("Should mint a ship with correct payment", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      const tx = await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const shipCount = await ships.read.shipCount();
      expect(shipCount).to.equal(1n);

      const ship = await ships.read.ships([1n]);
      expect(ship[10].toLowerCase()).to.equal(
        user1.account.address.toLowerCase()
      ); // owner is at index 10 in the Ship struct

      // Check referral count increased
      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(1n);
    });

    it("Should revert with invalid payment", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      await expect(
        ships.write.mintShip([user1.account.address, user2.account.address], {
          value: parseEther("0.5"),
        })
      ).to.be.rejectedWith("InvalidPayment");
    });

    it("Should revert with zero address referral", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      await expect(
        ships.write.mintShip(
          [user1.account.address, "0x0000000000000000000000000000000000000000"],
          { value: parseEther("1") }
        )
      ).to.be.rejectedWith("InvalidReferral");
    });
  });

  describe("Owner Functions", function () {
    it("Should allow owner to set ship price", async function () {
      const { ships, owner } = await loadFixture(deployShipsFixture);

      await ships.write.setShipPrice([parseEther("2")]);
      const newPrice = await ships.read.shipPrice();
      expect(newPrice).to.equal(parseEther("2"));
    });

    it("Should allow owner to set game address", async function () {
      const { ships, owner, user1 } = await loadFixture(deployShipsFixture);

      await ships.write.setGameAddress([user1.account.address]);
      const gameAddress = await ships.read.gameAddress();
      expect(gameAddress.toLowerCase()).to.equal(
        user1.account.address.toLowerCase()
      );
    });

    it("Should allow owner to set paused state", async function () {
      const { ships, owner } = await loadFixture(deployShipsFixture);

      await ships.write.setPaused([true]);
      const paused = await ships.read.paused();
      expect(paused).to.be.true;
    });

    it("Should not allow non-owner to set ship price", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      await expect(
        ships.write.setShipPrice([parseEther("2")], {
          account: user1.account,
        })
      ).to.be.rejectedWith(
        'OwnableUnauthorizedAccount("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")'
      );
    });
  });

  describe("Referral System", function () {
    it("Should process referral payment correctly", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      const initialBalance = await publicClient.getBalance({
        address: user2.account.address,
      });

      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      const finalBalance = await publicClient.getBalance({
        address: user2.account.address,
      });

      // Check that referral received 10% (first tier)
      expect(finalBalance - initialBalance).to.equal(parseEther("0.01"));
    });

    it("Should update referral count correctly", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(1n);
    });
  });
});
