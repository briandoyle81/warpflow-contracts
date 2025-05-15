import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther } from "viem";
import DeployModule from "../ignition/modules/DeployAndConfig";

describe("Ships", function () {
  // Deploy function to set up the initial state
  async function deployShipsFixture() {
    const [owner, user1, user2] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy all contracts using the Ignition module
    const {
      ships,
      mockShipNames,
      metadataRenderer,
      randomManager,
      imageRenderer,
      renderSpecial,
      renderAft,
      renderWeapon,
      renderBody,
      renderFore,
      renderSpecial1,
      renderSpecial2,
      renderSpecial3,
      renderAft0,
      renderAft1,
      renderAft2,
      renderWeapon1,
      renderWeapon2,
      renderWeapon3,
      renderShield1,
      renderShield2,
      renderShield3,
      renderArmor1,
      renderArmor2,
      renderArmor3,
      renderFore0,
      renderFore1,
      renderFore2,
    } = await hre.ignition.deploy(DeployModule);

    return {
      ships,
      mockShipNames,
      metadataRenderer,
      randomManager,
      imageRenderer,
      renderSpecial,
      renderAft,
      renderWeapon,
      renderBody,
      renderFore,
      renderSpecial1,
      renderSpecial2,
      renderSpecial3,
      renderAft0,
      renderAft1,
      renderAft2,
      renderWeapon1,
      renderWeapon2,
      renderWeapon3,
      renderShield1,
      renderShield2,
      renderShield3,
      renderArmor1,
      renderArmor2,
      renderArmor3,
      renderFore0,
      renderFore1,
      renderFore2,
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
      const { ships, user1, user2, publicClient, randomManager } =
        await loadFixture(deployShipsFixture);

      // Mint a ship first
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Get the ship's serial number
      const ship = await ships.read.ships([1n]);
      const serialNumber = ship[3].serialNumber; // traits is at index 3

      // Fulfill the random request
      await randomManager.write.fulfillRandomRequest([serialNumber]);

      // Construct the ship
      await ships.write.constructShip([1n], {
        account: user1.account,
      });

      // Get the ship data
      const constructedShip = await ships.read.ships([1n]);

      // Verify construction
      expect(constructedShip[9]).to.be.true; // constructed flag
      expect(constructedShip[0]).to.equal("Mock Ship"); // name from mock contract
      expect(constructedShip[6]).to.equal(1); // costsVersion should be set
      expect(constructedShip[7]).to.be.greaterThan(0); // cost should be calculated
    });

    it("Should allow owner to construct multiple ships at once", async function () {
      const { ships, user1, user2, publicClient, randomManager } =
        await loadFixture(deployShipsFixture);

      // Mint a 10-pack
      const tenPackPrice = await ships.read.tenPackPrice();
      await ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Get all ships' serial numbers
      for (let i = 1; i <= 10; i++) {
        const ship = await ships.read.ships([BigInt(i)]);
        const serialNumber = ship[3].serialNumber;
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships at once
      const shipIds = Array.from({ length: 10 }, (_, i) => BigInt(i + 1));
      await ships.write.constructShips([shipIds], {
        account: user1.account,
      });

      // Verify all ships are constructed
      for (let i = 1; i <= 10; i++) {
        const ship = await ships.read.ships([BigInt(i)]);
        expect(ship[9]).to.be.true; // constructed flag
        expect(ship[0]).to.equal("Mock Ship"); // name from mock contract
        expect(ship[6]).to.equal(1); // costsVersion should be set
        expect(ship[7]).to.be.greaterThan(0); // cost should be calculated
      }
    });

    it("Should not allow non-owner to construct ship", async function () {
      const { ships, user1, user2, randomManager } = await loadFixture(
        deployShipsFixture
      );

      // Mint a ship first
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Get the ship's serial number
      const ship = await ships.read.ships([1n]);
      const serialNumber = ship[3].serialNumber;

      // Fulfill the random request
      await randomManager.write.fulfillRandomRequest([serialNumber]);

      // Try to construct as non-owner
      await expect(
        ships.write.constructShip([1n], {
          account: user2.account,
        })
      ).to.be.rejectedWith("NotYourShip");
    });

    it("Should not allow constructing an already constructed ship", async function () {
      const { ships, user1, user2, randomManager } = await loadFixture(
        deployShipsFixture
      );

      // Mint a ship first
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Get the ship's serial number
      const ship = await ships.read.ships([1n]);
      const serialNumber = ship[3].serialNumber;

      // Fulfill the random request
      await randomManager.write.fulfillRandomRequest([serialNumber]);

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
  });

  describe("Token URI", function () {
    it("Should return valid metadata for a constructed ship", async function () {
      const { ships, user1, user2, publicClient, randomManager } =
        await loadFixture(deployShipsFixture);

      // Mint and construct a ship
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Get the ship's serial number
      const ship = await ships.read.ships([1n]);
      const serialNumber = ship[3].serialNumber;

      // Fulfill the random request
      await randomManager.write.fulfillRandomRequest([serialNumber]);

      await ships.write.constructShip([1n], {
        account: user1.account,
      });

      // Get the token URI
      const tokenURI = await ships.read.tokenURI([1n]);

      // Verify it's a base64 encoded data URI
      expect(tokenURI).to.match(/^data:application\/json;base64,/);

      // Decode the base64 content
      const base64Content = tokenURI.replace(
        "data:application/json;base64,",
        ""
      );
      const decodedContent = Buffer.from(base64Content, "base64").toString();
      const metadata = JSON.parse(decodedContent);

      // Verify basic metadata structure
      expect(metadata).to.have.property("name");
      expect(metadata).to.have.property("description");
      expect(metadata).to.have.property("attributes").that.is.an("array");
      expect(metadata).to.have.property("image").that.is.a("string");

      // Verify name format
      expect(metadata.name).to.match(/^Mock Ship #1$/);

      // Verify description
      expect(metadata.description).to.equal(
        "A unique spaceship in the Warpflow universe. Each ship has unique traits, equipment, and stats that determine its capabilities in battle."
      );

      console.log(metadata);

      // Verify image format - should now be a base64 encoded SVG
      expect(metadata.image).to.match(/^data:image\/svg\+xml;base64,/);

      // Verify attributes structure
      const attributes = metadata.attributes;
      expect(attributes).to.be.an("array");

      // Create a map of attributes for easier verification
      const attributeMap = new Map(
        attributes.map(
          (attr: { trait_type: string; value: string | number | boolean }) => [
            attr.trait_type,
            attr.value,
          ]
        )
      );

      // Verify required traits
      expect(attributeMap.has("Serial Number")).to.be.true;
      expect(attributeMap.has("Variant")).to.be.true;
      expect(attributeMap.has("Accuracy")).to.be.true;
      expect(attributeMap.has("Hull")).to.be.true;
      expect(attributeMap.has("Speed")).to.be.true;
      expect(attributeMap.has("Shiny")).to.be.true;
      expect(attributeMap.has("Ships Destroyed")).to.be.true;
      expect(attributeMap.has("Cost")).to.be.true;

      // Verify equipment traits
      expect(attributeMap.has("Main Weapon")).to.be.true;
      expect(attributeMap.has("Armor")).to.be.true;
      expect(attributeMap.has("Shields")).to.be.true;
      expect(attributeMap.has("Special")).to.be.true;

      // Verify stats traits
      expect(attributeMap.has("Range")).to.be.true;
      expect(attributeMap.has("Gun Damage")).to.be.true;
      expect(attributeMap.has("Hull Points")).to.be.true;
      expect(attributeMap.has("Movement")).to.be.true;

      // Verify numeric values are actually numbers
      expect(Number(attributeMap.get("Accuracy"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Hull"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Speed"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Ships Destroyed"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Cost"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Range"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Gun Damage"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Hull Points"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Movement"))).to.not.be.NaN;

      // Verify boolean values
      const shinyValue = attributeMap.get("Shiny");
      expect(shinyValue?.toString()).to.be.oneOf(["true", "false"]);

      // Verify equipment values are strings
      expect(attributeMap.get("Main Weapon")).to.be.a("string");
      expect(attributeMap.get("Armor")).to.be.a("string");
      expect(attributeMap.get("Shields")).to.be.a("string");
      expect(attributeMap.get("Special")).to.be.a("string");
    });

    it("Should revert for non-existent token", async function () {
      const { ships } = await loadFixture(deployShipsFixture);

      await expect(ships.read.tokenURI([999n])).to.be.rejectedWith("InvalidId");
    });
  });
});
