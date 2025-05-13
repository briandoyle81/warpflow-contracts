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
      expect(contractOwner.toString().toLocaleLowerCase()).to.equal(
        owner.account.address.toLocaleLowerCase()
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
      expect(ship[11].toString().toLocaleLowerCase()).to.equal(
        user1.account.address.toLocaleLowerCase()
      ); // owner is at index 11 in the Ship struct

      // Check referral count increased
      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(parseEther("1"));
    });

    it("Should mint ten ships with correct payment", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      const tenPackPrice = await ships.read.tenPackPrice();

      const tx = await ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const shipCount = await ships.read.shipCount();
      expect(shipCount).to.equal(10n);

      // Check all ships are owned by user1
      for (let i = 1; i <= 10; i++) {
        const ship = await ships.read.ships([BigInt(i)]);
        expect(ship[11].toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }

      // Check referral count increased by 10
      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(parseEther("8"));
    });

    it("Should revert ten pack with invalid payment", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      const tenPackPrice = await ships.read.tenPackPrice();
      const invalidPayment = tenPackPrice - parseEther("1"); // Pay 1 Flow less than required

      await expect(
        ships.write.mintTenPack(
          [user1.account.address, user2.account.address],
          { value: invalidPayment }
        )
      ).to.be.rejectedWith("InvalidPayment");
    });

    it("Should revert ten pack with zero address referral", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      const tenPackPrice = await ships.read.tenPackPrice();

      await expect(
        ships.write.mintTenPack(
          [user1.account.address, "0x0000000000000000000000000000000000000000"],
          { value: tenPackPrice }
        )
      ).to.be.rejectedWith("InvalidReferral");
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
      expect(gameAddress.toString().toLocaleLowerCase()).to.equal(
        user1.account.address.toLocaleLowerCase()
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

      // Check that referral received 1% (first tier)
      expect(finalBalance - initialBalance).to.equal(parseEther("0.01"));
    });

    it("Should process referral payment correctly for ten pack", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      const tenPackPrice = await ships.read.tenPackPrice();
      const initialBalance = await publicClient.getBalance({
        address: user2.account.address,
      });

      await ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      const finalBalance = await publicClient.getBalance({
        address: user2.account.address,
      });

      // Check that referral received 1% of ten pack price (first tier)
      // For 8 Flow, 1% is 0.08 Flow
      expect(finalBalance - initialBalance).to.equal(parseEther("0.08"));
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
      expect(referralCount).to.equal(parseEther("1"));
    });
  });

  describe("Ship Construction", function () {
    it("Should allow owner to construct their ship", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // Mint a ship first
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Construct the ship
      await ships.write.constructShip([1n], {
        account: user1.account,
      });

      // Get the ship data
      const ship = await ships.read.ships([1n]);

      // Verify construction
      expect(ship[9]).to.be.true; // constructed flag
      expect(ship[0]).to.equal("Mock Ship"); // name from mock contract
      expect(ship[6]).to.equal(1); // costsVersion should be set
      expect(ship[7]).to.be.greaterThan(0); // cost should be calculated
    });

    it("Should allow owner to construct multiple ships at once", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // Mint a 10-pack
      const tenPackPrice = await ships.read.tenPackPrice();
      await ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Construct all ships at once
      const shipIds = Array.from({ length: 10 }, (_, i) => BigInt(i + 1));
      await ships.write.constructShips([shipIds], {
        account: user1.account,
      });

      // Create an array of ship data
      const shipData = [];

      // Verify all ships are constructed
      for (let i = 1; i <= 10; i++) {
        const ship = await ships.read.ships([BigInt(i)]);
        shipData.push(ship);
      }

      // Verify all ships are constructed
      for (let i = 0; i < 10; i++) {
        expect(shipData[i][9]).to.be.true; // constructed flag
        expect(shipData[i][0]).to.equal("Mock Ship"); // name from mock contract
        expect(shipData[i][6]).to.equal(1); // costsVersion should be set
        expect(shipData[i][7]).to.be.greaterThan(0); // cost should be calculated
      }

      console.log(shipData);
    });

    it("Should not allow non-owner to construct ship", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      // Mint a ship first
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Try to construct as non-owner
      await expect(
        ships.write.constructShip([1n], {
          account: user2.account,
        })
      ).to.be.rejectedWith("NotYourShip");
    });

    it("Should not allow constructing an already constructed ship", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      // Mint a ship first
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Construct the ship
      await ships.write.constructShip([1n], {
        account: user1.account,
      });

      // Try to construct again
      await expect(
        ships.write.constructShip([1n], {
          account: user1.account,
        })
      ).to.be.rejectedWith("ShipConstructed");
    });

    it("Should set ship traits and equipment after construction", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      // Mint a ship first
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Construct the ship
      await ships.write.constructShip([1n], {
        account: user1.account,
      });

      // Get the ship data
      const ship = await ships.read.ships([1n]);

      // Verify traits and equipment are set
      const traits = ship[3]; // traits struct
      const equipment = ship[2]; // equipment struct

      // TODO
    });
  });
});
