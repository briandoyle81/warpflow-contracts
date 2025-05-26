import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther } from "viem";
import DeployModule from "../ignition/modules/DeployAndConfig";

describe("Ships", function () {
  // Deploy function to set up the initial state
  async function deployShipsFixture() {
    const [owner, user1, user2, user3] = await hre.viem.getWalletClients();
    const publicClient = await hre.viem.getPublicClient();

    // Deploy all contracts using the Ignition module
    const {
      ships,
      shipNames,
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

    // Create a separate contract instance for user1
    const user1Ships = await hre.viem.getContractAt("Ships", ships.address, {
      client: { wallet: user1 },
    });

    // Create a separate contract instance for user2
    const user2Ships = await hre.viem.getContractAt("Ships", ships.address, {
      client: { wallet: user2 },
    });

    // Create a separate contract instance for user3
    const user3Ships = await hre.viem.getContractAt("Ships", ships.address, {
      client: { wallet: user3 },
    });

    return {
      ships,
      user1Ships,
      user2Ships,
      user3Ships,
      shipNames,
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
      user3,
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
      expect(ship[6].toString().toLocaleLowerCase()).to.equal(
        user1.account.address.toLocaleLowerCase()
      ); // owner is at index 6 in the Ship struct

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
        expect(ship[6].toLocaleLowerCase()).to.equal(
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
      const config = await ships.read.config();
      expect(config[0].toString().toLocaleLowerCase()).to.equal(
        user1.account.address.toLocaleLowerCase()
      ); // gameAddress is first element in config struct
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
      expect(constructedShip[5].constructed).to.be.true; // shipData is at index 5
      expect(constructedShip[0]).to.equal("Mock Ship"); // name is at index 0
      expect(constructedShip[5].costsVersion).to.equal(1); // shipData.costsVersion
      expect(constructedShip[5].cost).to.be.greaterThan(0); // shipData.cost
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
        const serialNumber = ship[3].serialNumber; // traits is at index 3
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
        expect(ship[5].constructed).to.be.true; // shipData is at index 5
        expect(ship[0]).to.equal("Mock Ship"); // name is at index 0
        expect(ship[5].costsVersion).to.equal(1); // shipData.costsVersion
        expect(ship[5].cost).to.be.greaterThan(0); // shipData.cost
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
      const serialNumber = ship[3].serialNumber; // traits is at index 3

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
      const serialNumber = ship[3].serialNumber; // traits is at index 3

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
      const serialNumber = ship[3].serialNumber; // traits is at index 3

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

      // Verify numeric values are actually numbers
      expect(Number(attributeMap.get("Accuracy"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Hull"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Speed"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Ships Destroyed"))).to.not.be.NaN;
      expect(Number(attributeMap.get("Cost"))).to.not.be.NaN;

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

  describe("Ownership Changes", function () {
    it("Should not allow transfer without purchasing a 10-pack", async function () {
      const { ships, user1, user2, user3 } = await loadFixture(
        deployShipsFixture
      );

      // Verify user1 is not allowed to transfer initially
      const isAllowed = await ships.read.allowedToTransfer([
        user1.account.address,
      ]);
      expect(isAllowed).to.be.false;

      // Mint a ship to user1
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Verify user1 is still not allowed to transfer
      const isAllowedAfter = await ships.read.allowedToTransfer([
        user1.account.address,
      ]);
      expect(isAllowedAfter).to.be.false;

      // Try to transfer without purchasing a 10-pack
      await expect(
        ships.write.transferFrom(
          [user1.account.address, user3.account.address, 1n],
          { account: user1.account }
        )
      ).to.be.rejectedWith("NotAllowedToTransfer");
    });

    it("Should allow owner to transfer their ship after purchasing a 10-pack", async function () {
      const { ships, user1Ships, user2Ships, user1, user2, publicClient } =
        await loadFixture(deployShipsFixture);

      // First purchase a 10-pack to enable trading
      const tenPackPrice = await ships.read.tenPackPrice();
      await user1Ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Mint a 10-pack to user2 so they can transfer
      await user2Ships.write.mintTenPack(
        [user2.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Confirm user1 is allowed to transfer
      const isAllowed = await user1Ships.read.allowedToTransfer([
        user1.account.address,
      ]);
      expect(isAllowed).to.be.true;

      // Confirm user2 is allowed to transfer
      const isAllowed2 = await user2Ships.read.allowedToTransfer([
        user2.account.address,
      ]);
      expect(isAllowed2).to.be.true;

      // Transfer the ship from user1 to user2
      await user1Ships.write.transferFrom([
        user1.account.address,
        user2.account.address,
        1n,
      ]);

      // Verify new owner
      const newOwner = await ships.read.ownerOf([1n]);
      expect(newOwner.toString().toLocaleLowerCase()).to.equal(
        user2.account.address.toLocaleLowerCase()
      );
    });

    it("Should allow approved address to transfer ship after purchasing a 10-pack", async function () {
      const {
        ships,
        user1Ships,
        user2Ships,
        user3Ships,
        user1,
        user2,
        user3,
        publicClient,
      } = await loadFixture(deployShipsFixture);

      // First purchase a 10-pack to enable trading for user1 (the owner)
      const tenPackPrice = await ships.read.tenPackPrice();
      await user1Ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Purchase a 10-pack for user3 (the receiver)
      await user3Ships.write.mintTenPack(
        [user3.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Confirm user1 is allowed to transfer
      const isAllowed = await user1Ships.read.allowedToTransfer([
        user1.account.address,
      ]);
      expect(isAllowed).to.be.true;

      // Confirm user3 is allowed to receive
      const isAllowed3 = await user3Ships.read.allowedToTransfer([
        user3.account.address,
      ]);
      expect(isAllowed3).to.be.true;

      // User1 approves user2 to transfer their ship
      await user1Ships.write.approve([user2.account.address, 1n]);

      // User2 transfers the ship to user3
      await user2Ships.write.transferFrom([
        user1.account.address,
        user3.account.address,
        1n,
      ]);

      // Verify new owner
      const newOwner = await ships.read.ownerOf([1n]);
      expect(newOwner.toString().toLocaleLowerCase()).to.equal(
        user3.account.address.toLocaleLowerCase()
      );
    });

    it("Should allow operator to transfer ship after purchasing a 10-pack", async function () {
      const {
        ships,
        user1Ships,
        user2Ships,
        user3Ships,
        user1,
        user2,
        user3,
        publicClient,
      } = await loadFixture(deployShipsFixture);

      // First purchase a 10-pack to enable trading for user1 (the owner)
      const tenPackPrice = await ships.read.tenPackPrice();
      await user1Ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Purchase a 10-pack for user3 (the receiver)
      await user3Ships.write.mintTenPack(
        [user3.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Confirm user1 is allowed to transfer
      const isAllowed = await user1Ships.read.allowedToTransfer([
        user1.account.address,
      ]);
      expect(isAllowed).to.be.true;

      // Confirm user3 is allowed to receive
      const isAllowed3 = await user3Ships.read.allowedToTransfer([
        user3.account.address,
      ]);
      expect(isAllowed3).to.be.true;

      // User1 sets user2 as operator
      await user1Ships.write.setApprovalForAll([user2.account.address, true]);

      // User2 transfers the ship to user3
      await user2Ships.write.transferFrom([
        user1.account.address,
        user3.account.address,
        1n,
      ]);

      // Verify new owner
      const newOwner = await ships.read.ownerOf([1n]);
      expect(newOwner.toString().toLocaleLowerCase()).to.equal(
        user3.account.address.toLocaleLowerCase()
      );
    });

    it("Should not allow non-owner to transfer ship even with 10-pack", async function () {
      const {
        ships,
        user1Ships,
        user2Ships,
        user3Ships,
        user1,
        user2,
        user3,
        publicClient,
      } = await loadFixture(deployShipsFixture);

      // First purchase a 10-pack to enable trading for user1 (the owner)
      const tenPackPrice = await ships.read.tenPackPrice();
      await user1Ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Purchase a 10-pack for user2 (the non-owner)
      await user2Ships.write.mintTenPack(
        [user2.account.address, user1.account.address],
        { value: tenPackPrice }
      );

      // Purchase a 10-pack for user3 (the receiver)
      await user3Ships.write.mintTenPack(
        [user3.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Confirm all users are allowed to transfer
      const isAllowed1 = await user1Ships.read.allowedToTransfer([
        user1.account.address,
      ]);
      const isAllowed2 = await user2Ships.read.allowedToTransfer([
        user2.account.address,
      ]);
      const isAllowed3 = await user3Ships.read.allowedToTransfer([
        user3.account.address,
      ]);
      expect(isAllowed1).to.be.true;
      expect(isAllowed2).to.be.true;
      expect(isAllowed3).to.be.true;

      // Try to transfer as non-owner
      await expect(
        user2Ships.write.transferFrom([
          user1.account.address,
          user3.account.address,
          1n,
        ])
      ).to.be.rejectedWith("ERC721InsufficientApproval");
    });

    it("Should not allow transfer of destroyed ship even with 10-pack", async function () {
      const { ships, user1, user2, owner, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // First purchase a 10-pack to enable trading
      const tenPackPrice = await ships.read.tenPackPrice();
      await ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Mint a ship to user1
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Destroy the ship (simulate by setting timestampDestroyed)
      await ships.write.setTimestampDestroyed([1n], { account: owner.account });

      // Try to transfer destroyed ship
      await expect(
        ships.write.transferFrom(
          [user1.account.address, user2.account.address, 1n],
          { account: user1.account }
        )
      ).to.be.rejectedWith("Ship destroyed");
    });

    it("Should update shipsOwned mapping on transfer after 10-pack purchase", async function () {
      const { ships, user1Ships, user2Ships, user1, user2, publicClient } =
        await loadFixture(deployShipsFixture);

      // First purchase a 10-pack to enable trading for user1 (the owner)
      const tenPackPrice = await ships.read.tenPackPrice();
      await user1Ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Purchase a 10-pack for user2 (the receiver)
      await user2Ships.write.mintTenPack(
        [user2.account.address, user1.account.address],
        { value: tenPackPrice }
      );

      // Confirm both users are allowed to transfer
      const isAllowed1 = await user1Ships.read.allowedToTransfer([
        user1.account.address,
      ]);
      const isAllowed2 = await user2Ships.read.allowedToTransfer([
        user2.account.address,
      ]);
      expect(isAllowed1).to.be.true;
      expect(isAllowed2).to.be.true;

      // Verify initial state
      const initialUser1Ships = await ships.read.getShipsOwned([
        user1.account.address,
      ]);
      expect(initialUser1Ships.length).to.equal(10); // 10 from ten pack

      // Transfer the ship
      const tx = await user1Ships.write.transferFrom([
        user1.account.address,
        user2.account.address,
        1n,
      ]);

      // Wait for the transaction to be mined
      await publicClient.waitForTransactionReceipt({ hash: tx });

      // Check shipsOwned mapping
      const user1ShipsList = await ships.read.getShipsOwned([
        user1.account.address,
      ]);
      const user2ShipsList = await ships.read.getShipsOwned([
        user2.account.address,
      ]);

      // Verify the ship is only in user2's list after transfer
      expect(user1ShipsList.length).to.equal(9); // Should have 9 ships left
      expect(user2ShipsList.length).to.equal(11); // Should have 10 from ten pack + 1 transferred
      expect(user2ShipsList[10].id).to.equal(1n); // The transferred ship should be id 1

      // Verify the actual owner is user2
      const owner = await ships.read.ownerOf([1n]);
      expect(owner.toString().toLocaleLowerCase()).to.equal(
        user2.account.address.toLocaleLowerCase()
      );
    });

    it("Should allow owner to approve and revoke approval after 10-pack purchase", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // First purchase a 10-pack to enable trading
      const tenPackPrice = await ships.read.tenPackPrice();
      await ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Mint a ship to user1
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Approve user2
      await ships.write.approve([user2.account.address, 1n], {
        account: user1.account,
      });

      // Verify approval
      const approved = await ships.read.getApproved([1n]);
      expect(approved.toString().toLocaleLowerCase()).to.equal(
        user2.account.address.toLocaleLowerCase()
      );

      // Revoke approval
      await ships.write.approve(
        ["0x0000000000000000000000000000000000000000", 1n],
        { account: user1.account }
      );

      // Verify approval revoked
      const newApproved = await ships.read.getApproved([1n]);
      expect(newApproved).to.equal(
        "0x0000000000000000000000000000000000000000"
      );
    });

    it("Should allow owner to set and revoke operator after 10-pack purchase", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // First purchase a 10-pack to enable trading
      const tenPackPrice = await ships.read.tenPackPrice();
      await ships.write.mintTenPack(
        [user1.account.address, user2.account.address],
        { value: tenPackPrice }
      );

      // Mint a ship to user1
      await ships.write.mintShip(
        [user1.account.address, user2.account.address],
        { value: parseEther("1") }
      );

      // Set user2 as operator
      await ships.write.setApprovalForAll([user2.account.address, true], {
        account: user1.account,
      });

      // Verify operator status
      const isOperator = await ships.read.isApprovedForAll([
        user1.account.address,
        user2.account.address,
      ]);
      expect(isOperator).to.be.true;

      // Revoke operator status
      await ships.write.setApprovalForAll([user2.account.address, false], {
        account: user1.account,
      });

      // Verify operator status revoked
      const isOperatorAfter = await ships.read.isApprovedForAll([
        user1.account.address,
        user2.account.address,
      ]);
      expect(isOperatorAfter).to.be.false;
    });
  });
});
