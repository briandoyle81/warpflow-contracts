import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther } from "viem";
import DeployModule from "../ignition/modules/DeployAndConfig";
import {
  Ship,
  ShipData,
  ShipEquipment,
  ShipTraits,
  ShipTuple,
  tupleToShip,
} from "./types";

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
      universalCredits,
      shipPurchaser,
      shipAttributes,
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

    // Create separate contract instances for UniversalCredits
    const user1UC = await hre.viem.getContractAt(
      "UniversalCredits",
      universalCredits.address,
      {
        client: { wallet: user1 },
      }
    );
    const user2UC = await hre.viem.getContractAt(
      "UniversalCredits",
      universalCredits.address,
      {
        client: { wallet: user2 },
      }
    );
    const user3UC = await hre.viem.getContractAt(
      "UniversalCredits",
      universalCredits.address,
      {
        client: { wallet: user3 },
      }
    );

    // Create separate contract instances for ShipPurchaser
    const user1Purchaser = await hre.viem.getContractAt(
      "ShipPurchaser",
      shipPurchaser.address,
      {
        client: { wallet: user1 },
      }
    );
    const user2Purchaser = await hre.viem.getContractAt(
      "ShipPurchaser",
      shipPurchaser.address,
      {
        client: { wallet: user2 },
      }
    );
    const user3Purchaser = await hre.viem.getContractAt(
      "ShipPurchaser",
      shipPurchaser.address,
      {
        client: { wallet: user3 },
      }
    );

    // Approve the owner address to mint UC tokens
    await universalCredits.write.setAuthorizedToMint([
      owner.account.address,
      true,
    ]);

    // Mint some UC tokens to users for testing
    await universalCredits.write.mint([
      user1.account.address,
      parseEther("1000"),
    ]);
    await universalCredits.write.mint([
      user2.account.address,
      parseEther("1000"),
    ]);
    await universalCredits.write.mint([
      user3.account.address,
      parseEther("1000"),
    ]);

    // Approve ShipPurchaser to spend UC tokens
    await user1UC.write.approve([shipPurchaser.address, parseEther("1000")]);
    await user2UC.write.approve([shipPurchaser.address, parseEther("1000")]);
    await user3UC.write.approve([shipPurchaser.address, parseEther("1000")]);

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
      universalCredits,
      shipPurchaser,
      shipAttributes,
      user1UC,
      user2UC,
      user3UC,
      user1Purchaser,
      user2Purchaser,
      user3Purchaser,
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

    it("Should set the correct initial tier prices", async function () {
      const { ships } = await loadFixture(deployShipsFixture);
      const [tiers, shipsPerTier, prices] = await ships.read.getPurchaseInfo();

      // Check tier 1 (5 ships for 4.99 Flow)
      expect(tiers[0]).to.equal(1);
      expect(shipsPerTier[0]).to.equal(5);
      expect(prices[0]).to.equal(parseEther("4.99"));

      // Check tier 2 (11 ships for 9.99 Flow)
      expect(tiers[1]).to.equal(2);
      expect(shipsPerTier[1]).to.equal(11);
      expect(prices[1]).to.equal(parseEther("9.99"));

      // Check tier 3 (28 ships for 24.99 Flow)
      expect(tiers[2]).to.equal(3);
      expect(shipsPerTier[2]).to.equal(28);
      expect(prices[2]).to.equal(parseEther("24.99"));

      // Check tier 4 (60 ships for 49.99 Flow)
      expect(tiers[3]).to.equal(4);
      expect(shipsPerTier[3]).to.equal(60);
      expect(prices[3]).to.equal(parseEther("49.99"));

      // Check tier 5 (125 ships for 99.99 Flow)
      expect(tiers[4]).to.equal(5);
      expect(shipsPerTier[4]).to.equal(125);
      expect(prices[4]).to.equal(parseEther("99.99"));
    });

    it("Should allow owner to set purchase info", async function () {
      const { ships, owner } = await loadFixture(deployShipsFixture);

      const newTiers = [1, 2, 3];
      const newShipsPerTier = [5, 10, 15];
      const newPrices = [
        parseEther("5.99"),
        parseEther("10.99"),
        parseEther("15.99"),
      ];

      await ships.write.setPurchaseInfo([newTiers, newShipsPerTier, newPrices]);

      const [tiers, shipsPerTier, prices] = await ships.read.getPurchaseInfo();
      expect(tiers).to.deep.equal(newTiers);
      expect(shipsPerTier).to.deep.equal(newShipsPerTier);
      expect(prices).to.deep.equal(newPrices);
    });

    it("Should not allow non-owner to set purchase info", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      const newTiers = [1, 2, 3];
      const newShipsPerTier = [5, 10, 15];
      const newPrices = [
        parseEther("5.99"),
        parseEther("10.99"),
        parseEther("15.99"),
      ];

      await expect(
        ships.write.setPurchaseInfo([newTiers, newShipsPerTier, newPrices], {
          account: user1.account,
        })
      ).to.be.rejectedWith(
        'OwnableUnauthorizedAccount("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")'
      );
    });

    it("Should allow owner to set game address", async function () {
      const { ships, owner, user1 } = await loadFixture(deployShipsFixture);

      await ships.write.setConfig([
        user1.account.address, // gameAddress
        "0x0000000000000000000000000000000000000000", // lobbyAddress
        "0x0000000000000000000000000000000000000000", // fleetsAddress
        "0x0000000000000000000000000000000000000000", // shipGenerator
        "0x0000000000000000000000000000000000000000", // randomManager
        "0x0000000000000000000000000000000000000000", // metadataRenderer
      ]);

      const config = await ships.read.config();
      expect(config[0].toString().toLowerCase()).to.equal(
        user1.account.address.toLowerCase()
      );
    });
  });

  describe("Minting", function () {
    it("Should tier 1 with correct payment", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      const tx = await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const shipCount = await ships.read.shipCount();
      expect(shipCount).to.equal(5n);

      // Check all ships are owned by user1
      for (let i = 1; i <= 5; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.owner.toString().toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }

      // Check referral count increased by 5 ships
      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(5n);
    });

    it("Should tier 2 with correct payment", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      const tx = await ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      await publicClient.waitForTransactionReceipt({ hash: tx });

      const shipCount = await ships.read.shipCount();
      expect(shipCount).to.equal(11n);

      // Check all ships are owned by user1
      for (let i = 1; i <= 11; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.owner.toString().toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }

      // Check referral count increased by 11 ships
      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(11n);
    });

    it("Should revert tier 1 with invalid payment", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      const invalidPayment = parseEther("3.99"); // Pay 1 Flow less than required

      await expect(
        ships.write.purchaseWithFlow(
          [user1.account.address, 0n, user2.account.address],
          { value: invalidPayment }
        )
      ).to.be.rejectedWith("InvalidPurchase");
    });

    it("Should revert tier 1 with zero address referral", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      await expect(
        ships.write.purchaseWithFlow(
          [
            user1.account.address,
            0n,
            "0x0000000000000000000000000000000000000000",
          ],
          { value: parseEther("4.99") }
        )
      ).to.be.rejectedWith("InvalidReferral");
    });

    it("Should revert with invalid payment", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      await expect(
        ships.write.purchaseWithFlow(
          [user1.account.address, 0n, user2.account.address],
          { value: parseEther("0.5") }
        )
      ).to.be.rejectedWith("InvalidPurchase");
    });

    it("Should revert with zero address referral", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      await expect(
        ships.write.purchaseWithFlow(
          [
            user1.account.address,
            0n,
            "0x0000000000000000000000000000000000000000",
          ],
          { value: parseEther("4.99") }
        )
      ).to.be.rejectedWith("InvalidReferral");
    });
  });

  describe("Owner Functions", function () {
    it("Should allow owner to set purchase info", async function () {
      const { ships, owner } = await loadFixture(deployShipsFixture);

      const newTiers = [1, 2, 3];
      const newShipsPerTier = [5, 10, 15];
      const newPrices = [
        parseEther("5.99"),
        parseEther("10.99"),
        parseEther("15.99"),
      ];

      await ships.write.setPurchaseInfo([newTiers, newShipsPerTier, newPrices]);

      const [tiers, shipsPerTier, prices] = await ships.read.getPurchaseInfo();
      expect(tiers).to.deep.equal(newTiers);
      expect(shipsPerTier).to.deep.equal(newShipsPerTier);
      expect(prices).to.deep.equal(newPrices);
    });

    it("Should not allow non-owner to set purchase info", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      const newTiers = [1, 2, 3];
      const newShipsPerTier = [5, 10, 15];
      const newPrices = [
        parseEther("5.99"),
        parseEther("10.99"),
        parseEther("15.99"),
      ];

      await expect(
        ships.write.setPurchaseInfo([newTiers, newShipsPerTier, newPrices], {
          account: user1.account,
        })
      ).to.be.rejectedWith(
        'OwnableUnauthorizedAccount("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")'
      );
    });

    it("Should allow owner to set game address", async function () {
      const { ships, owner, user1 } = await loadFixture(deployShipsFixture);

      await ships.write.setConfig([
        user1.account.address, // gameAddress
        "0x0000000000000000000000000000000000000000", // lobbyAddress
        "0x0000000000000000000000000000000000000000", // fleetsAddress
        "0x0000000000000000000000000000000000000000", // shipGenerator
        "0x0000000000000000000000000000000000000000", // randomManager
        "0x0000000000000000000000000000000000000000", // metadataRenderer
      ]);

      const config = await ships.read.config();
      expect(config[0].toString().toLowerCase()).to.equal(
        user1.account.address.toLowerCase()
      );
    });

    it("Should allow owner to set paused state", async function () {
      const { ships, owner } = await loadFixture(deployShipsFixture);

      await ships.write.setPaused([true]);
      const paused = await ships.read.paused();
      expect(paused).to.be.true;
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

      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      const finalBalance = await publicClient.getBalance({
        address: user2.account.address,
      });

      // Check that referral received 1% (first tier)
      expect(finalBalance - initialBalance).to.equal(parseEther("0.0499"));

      // Check that referral count increased by 5 ships
      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(5n);
    });

    it("Should process referral payment correctly for tier 1", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      const initialBalance = await publicClient.getBalance({
        address: user2.account.address,
      });

      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      const finalBalance = await publicClient.getBalance({
        address: user2.account.address,
      });

      // Check that referral received 1% of tier 1 price (4.99 Flow)
      // For 4.99 Flow, 1% is 0.0499 Flow
      expect(finalBalance - initialBalance).to.equal(parseEther("0.0499"));

      // Check that referral count increased by 5 ships
      const referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(5n);
    });

    it("Should update referral count correctly", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      // Purchase tier 1 (5 ships)
      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      // Check referral count is 5
      let referralCount = await ships.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(5n);

      // Purchase another tier 1
      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      // Check referral count is now 10 (5 + 5)
      referralCount = await ships.read.referralCount([user2.account.address]);
      expect(referralCount).to.equal(10n);
    });
  });

  describe("Ship Construction", function () {
    it("Should allow owner to construct their ship", async function () {
      const { ships, user1, user2, publicClient, randomManager } =
        await loadFixture(deployShipsFixture);

      // Mint a ship first
      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      // Get the ship's serial number
      const shipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      const serialNumber = ship.traits.serialNumber; // traits is at index 3

      // Fulfill the random request
      await randomManager.write.fulfillRandomRequest([serialNumber]);

      // Construct the ship
      await ships.write.constructShip([1n], {
        account: user1.account,
      });

      // Get the ship data
      const constructedShipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const constructedShip = tupleToShip(constructedShipTuple);

      // Verify construction
      expect(constructedShip.shipData.constructed).to.be.true; // shipData is at index 5
      expect(constructedShip.name).to.equal("Mock Ship"); // name is at index 0
      expect(constructedShip.shipData.costsVersion).to.equal(1); // shipData.costsVersion
      expect(constructedShip.shipData.cost).to.be.greaterThan(0); // shipData.cost
    });

    it("Should allow owner to construct all tier 5 ships at once", async function () {
      const { ships, user1, user2, publicClient, randomManager } =
        await loadFixture(deployShipsFixture);

      // Purchase tier 5 (125 ships)
      await ships.write.purchaseWithFlow(
        [user1.account.address, 4n, user2.account.address],
        { value: parseEther("99.99") }
      );

      // Get all ships' serial numbers and fulfill random requests
      for (let i = 1; i <= 125; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber; // traits is at index 3
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships at once using constructAllMyShips
      await ships.write.constructAllMyShips({
        account: user1.account,
      });

      // Verify all ships are constructed
      for (let i = 1; i <= 125; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.shipData.constructed).to.be.true; // shipData is at index 5
        expect(ship.name).to.equal("Mock Ship"); // name is at index 0
        expect(ship.shipData.costsVersion).to.equal(1); // shipData.costsVersion
        expect(ship.shipData.cost).to.be.greaterThan(0); // shipData.cost
      }
    });

    it("Should allow owner to construct multiple ships at once", async function () {
      const { ships, user1, user2, publicClient, randomManager } =
        await loadFixture(deployShipsFixture);

      // Purchase tier 1 (5 ships)
      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      // Get all ships' serial numbers
      for (let i = 1; i <= 5; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        const serialNumber = ship.traits.serialNumber; // traits is at index 3
        await randomManager.write.fulfillRandomRequest([serialNumber]);
      }

      // Construct all ships at once
      const shipIds = Array.from({ length: 5 }, (_, i) => BigInt(i + 1));
      await ships.write.constructShips([shipIds], {
        account: user1.account,
      });

      // Verify all ships are constructed
      for (let i = 1; i <= 5; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.shipData.constructed).to.be.true; // shipData is at index 5
        expect(ship.name).to.equal("Mock Ship"); // name is at index 0
        expect(ship.shipData.costsVersion).to.equal(1); // shipData.costsVersion
        expect(ship.shipData.cost).to.be.greaterThan(0); // shipData.cost
      }
    });

    it("Should not allow non-owner to construct ship", async function () {
      const { ships, user1, user2, randomManager } = await loadFixture(
        deployShipsFixture
      );

      // Mint a ship first
      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      // Get the ship's serial number
      const shipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      const serialNumber = ship.traits.serialNumber; // traits is at index 3

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
      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      // Get the ship's serial number
      const shipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      const serialNumber = ship.traits.serialNumber; // traits is at index 3

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
      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user2.account.address],
        { value: parseEther("4.99") }
      );

      // Get the ship's serial number
      const shipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      const serialNumber = ship.traits.serialNumber; // traits is at index 3

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

      // Decode the image
      const image = metadata.image;
      const imageContent = image.replace("data:image/svg+xml;base64,", "");
      const decodedImage = Buffer.from(imageContent, "base64").toString();
      const svgString = decodedImage;

      // Verify the SVG string is valid
      // Log if the ship is shiny according to the metadata
      // console.log(
      //   "SHIP SHINY STATUS:",
      //   metadata.attributes.find(
      //     (attr: { trait_type: string; value: string | number | boolean }) =>
      //       attr.trait_type === "Shiny"
      //   )?.value
      // );

      // console.log(svgString);

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
      expect(shinyValue).to.be.oneOf(["Yes", "No"]);

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
    it("Should not allow transfer without purchasing a tier", async function () {
      const { ships, user1, user2, user3 } = await loadFixture(
        deployShipsFixture
      );

      // Verify user1 has not purchased enough ships to transfer initially
      const amountPurchased = await ships.read.amountPurchased([
        user1.account.address,
      ]);
      expect(Number(amountPurchased)).to.be.lessThan(10);

      // Mint ships to user1 using tier 1 (which gives 11 ships, enough to transfer)
      await ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Verify user1 has now purchased enough ships to transfer (since they purchased tier 1)
      const amountPurchasedAfter = await ships.read.amountPurchased([
        user1.account.address,
      ]);
      expect(Number(amountPurchasedAfter)).to.be.greaterThanOrEqual(10);

      // Try to transfer without purchasing a tier for user3
      await expect(
        ships.write.transferFrom(
          [user1.account.address, user3.account.address, 1n],
          { account: user1.account }
        )
      ).to.be.rejectedWith("InsufficientPurchases");
    });

    it("Should allow owner to transfer their ship after purchasing a tier", async function () {
      const { ships, user1Ships, user2Ships, user1, user2, publicClient } =
        await loadFixture(deployShipsFixture);

      // First purchase tier 1 to enable trading (gives 11 ships, enough to transfer)
      await user1Ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Mint tier 1 to user2 so they can transfer (gives 11 ships, enough to transfer)
      await user2Ships.write.purchaseWithFlow(
        [user2.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Confirm user1 has purchased enough ships to transfer
      const amountPurchased1 = await user1Ships.read.amountPurchased([
        user1.account.address,
      ]);
      expect(Number(amountPurchased1)).to.be.greaterThanOrEqual(10);

      // Confirm user2 has purchased enough ships to transfer
      const amountPurchased2 = await user2Ships.read.amountPurchased([
        user2.account.address,
      ]);
      expect(Number(amountPurchased2)).to.be.greaterThanOrEqual(10);

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

    it("Should allow approved address to transfer ship after purchasing a tier", async function () {
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

      // First purchase tier 1 to enable trading for user1 (the owner) - gives 11 ships
      await user1Ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Purchase tier 1 for user3 (the receiver) - gives 11 ships
      await user3Ships.write.purchaseWithFlow(
        [user3.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Confirm user1 has purchased enough ships to transfer
      const amountPurchased1 = await user1Ships.read.amountPurchased([
        user1.account.address,
      ]);
      expect(Number(amountPurchased1)).to.be.greaterThanOrEqual(10);

      // Confirm user3 has purchased enough ships to receive
      const amountPurchased3 = await user3Ships.read.amountPurchased([
        user3.account.address,
      ]);
      expect(Number(amountPurchased3)).to.be.greaterThanOrEqual(10);

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

    it("Should allow operator to transfer ship after purchasing a tier", async function () {
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

      // First purchase tier 1 to enable trading for user1 (the owner) - gives 11 ships
      await user1Ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Purchase tier 1 for user3 (the receiver) - gives 11 ships
      await user3Ships.write.purchaseWithFlow(
        [user3.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Confirm user1 has purchased enough ships to transfer
      const amountPurchased1 = await user1Ships.read.amountPurchased([
        user1.account.address,
      ]);
      expect(Number(amountPurchased1)).to.be.greaterThanOrEqual(10);

      // Confirm user3 has purchased enough ships to receive
      const amountPurchased3 = await user3Ships.read.amountPurchased([
        user3.account.address,
      ]);
      expect(Number(amountPurchased3)).to.be.greaterThanOrEqual(10);

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

    it("Should not allow non-owner to transfer ship even with tier purchase", async function () {
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

      // First purchase tier 1 to enable trading for user1 (the owner) - gives 11 ships
      await user1Ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Purchase tier 1 for user2 (the non-owner) - gives 11 ships
      await user2Ships.write.purchaseWithFlow(
        [user2.account.address, 1n, user1.account.address],
        { value: parseEther("9.99") }
      );

      // Purchase tier 1 for user3 (the receiver) - gives 11 ships
      await user3Ships.write.purchaseWithFlow(
        [user3.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Confirm all users have purchased enough ships to transfer
      const amountPurchased1 = await user1Ships.read.amountPurchased([
        user1.account.address,
      ]);
      const amountPurchased2 = await user2Ships.read.amountPurchased([
        user2.account.address,
      ]);
      const amountPurchased3 = await user3Ships.read.amountPurchased([
        user3.account.address,
      ]);
      expect(Number(amountPurchased1)).to.be.greaterThanOrEqual(10);
      expect(Number(amountPurchased2)).to.be.greaterThanOrEqual(10);
      expect(Number(amountPurchased3)).to.be.greaterThanOrEqual(10);

      // Try to transfer as non-owner
      await expect(
        user2Ships.write.transferFrom([
          user1.account.address,
          user3.account.address,
          1n,
        ])
      ).to.be.rejectedWith("ERC721InsufficientApproval");
    });

    it("Should not allow transfer of destroyed ship even with tier purchase", async function () {
      const { ships, user1, user2, owner, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // First purchase tier 1 to enable trading - gives 11 ships
      await ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Note: The first purchase already gives 11 ships, no need for a second purchase

      // Destroy the ship (simulate by setting timestampDestroyed)
      await ships.write.setTimestampDestroyed([1n, 0n], {
        account: owner.account,
      });

      // Try to transfer destroyed ship
      await expect(
        ships.write.transferFrom(
          [user1.account.address, user2.account.address, 1n],
          { account: user1.account }
        )
      ).to.be.rejectedWith("Ship destroyed");
    });

    it("Should update shipsOwned mapping on transfer after tier purchase", async function () {
      const { ships, user1Ships, user2Ships, user1, user2, publicClient } =
        await loadFixture(deployShipsFixture);

      // First purchase tier 1 to enable trading for user1 (the owner) - gives 11 ships
      await user1Ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Purchase tier 1 for user2 (the receiver) - gives 11 ships
      await user2Ships.write.purchaseWithFlow(
        [user2.account.address, 1n, user1.account.address],
        { value: parseEther("9.99") }
      );

      // Confirm both users have purchased enough ships to transfer
      const amountPurchased1 = await user1Ships.read.amountPurchased([
        user1.account.address,
      ]);
      const amountPurchased2 = await user2Ships.read.amountPurchased([
        user2.account.address,
      ]);
      expect(Number(amountPurchased1)).to.be.greaterThanOrEqual(10);
      expect(Number(amountPurchased2)).to.be.greaterThanOrEqual(10);

      // Verify initial state
      const initialUser1Ships = await ships.read.getShipIdsOwned([
        user1.account.address,
      ]);
      expect(initialUser1Ships.length).to.equal(11); // 11 from tier 1

      // Transfer the ship
      const tx = await user1Ships.write.transferFrom([
        user1.account.address,
        user2.account.address,
        1n,
      ]);

      // Wait for the transaction to be mined
      await publicClient.waitForTransactionReceipt({ hash: tx });

      // Check shipsOwned mapping
      const user1ShipsList = await ships.read.getShipIdsOwned([
        user1.account.address,
      ]);
      const user2ShipsList = await ships.read.getShipIdsOwned([
        user2.account.address,
      ]);

      // Verify the ship is only in user2's list after transfer
      expect(user1ShipsList.length).to.equal(10); // Should have 10 ships left
      expect(user2ShipsList.length).to.equal(12); // Should have 11 from tier 1 + 1 transferred
      expect(user2ShipsList[11]).to.equal(1n); // The transferred ship should be id 1

      // Verify the actual owner is user2
      const owner = await ships.read.ownerOf([1n]);
      expect(owner.toString().toLocaleLowerCase()).to.equal(
        user2.account.address.toLocaleLowerCase()
      );
    });

    it("Should allow owner to approve and revoke approval after tier purchase", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // First purchase tier 1 to enable trading - gives 11 ships
      await ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Note: The first purchase already gives 11 ships, no need for a second purchase

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

    it("Should allow owner to set and revoke operator after tier purchase", async function () {
      const { ships, user1, user2, publicClient } = await loadFixture(
        deployShipsFixture
      );

      // First purchase tier 1 to enable trading - gives 11 ships
      await ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Note: The first purchase already gives 11 ships, no need for a second purchase

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

  describe("Ship Creation", function () {
    it("Should allow authorized address to create ships", async function () {
      const { ships, user1, owner } = await loadFixture(deployShipsFixture);

      // Authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create 3 ships for user1
      await ships.write.createShips([user1.account.address, 3n], {
        account: user1.account,
      });

      // Verify ships were created
      const shipCount = await ships.read.shipCount();
      expect(shipCount).to.equal(3n);

      // Verify all ships are owned by user1
      for (let i = 1; i <= 3; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.owner.toString().toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }
    });

    it("Should not allow unauthorized address to create ships", async function () {
      const { ships, user1, user2 } = await loadFixture(deployShipsFixture);

      // Try to create ships without authorization
      await expect(
        ships.write.createShips([user1.account.address, 3n], {
          account: user2.account,
        })
      ).to.be.rejectedWith("NotAuthorized");
    });

    it("Should allow creating multiple ships in one transaction", async function () {
      const { ships, user1, owner } = await loadFixture(deployShipsFixture);

      // Authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create 10 ships for user1
      await ships.write.createShips([user1.account.address, 10n], {
        account: user1.account,
      });

      // Verify ships were created
      const shipCount = await ships.read.shipCount();
      expect(shipCount).to.equal(10n);

      // Verify all ships are owned by user1
      for (let i = 1; i <= 10; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.owner.toString().toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }
    });

    it("Should allow owner to create ships for any address", async function () {
      const { ships, user1, owner } = await loadFixture(deployShipsFixture);

      // First authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create 5 ships for user1 using owner account
      await ships.write.createShips([user1.account.address, 5n], {
        account: user1.account,
      });

      // Verify ships were created
      const shipCount = await ships.read.shipCount();
      expect(shipCount).to.equal(5n);

      // Verify all ships are owned by user1
      for (let i = 1; i <= 5; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.owner.toString().toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }
    });

    it("Should update shipsOwned mapping correctly", async function () {
      const { ships, user1, owner } = await loadFixture(deployShipsFixture);

      // First authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create 3 ships for user1
      await ships.write.createShips([user1.account.address, 3n], {
        account: user1.account,
      });

      // Verify shipsOwned mapping
      const user1Ships = await ships.read.getShipIdsOwned([
        user1.account.address,
      ]);
      expect(user1Ships.length).to.equal(3);
      expect(user1Ships[0]).to.equal(1n);
      expect(user1Ships[1]).to.equal(2n);
      expect(user1Ships[2]).to.equal(3n);
    });
  });

  describe("Specific Ship Construction", function () {
    it("Should allow authorized address to construct a specific ship", async function () {
      const { ships, user1, owner } = await loadFixture(deployShipsFixture);

      // First authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create a ship first
      await ships.write.createShips([user1.account.address, 1n], {
        account: user1.account,
      });

      // Create a specific ship configuration
      const specificShip = {
        name: "Custom Ship",
        id: 1n,
        equipment: {
          mainWeapon: 2,
          armor: 2,
          shields: 2,
          special: 2,
        },
        traits: {
          serialNumber: 123n,
          colors: {
            h1: 200,
            s1: 40,
            l1: 47,
            h2: 180,
            s2: 50,
            l2: 60,
          },
          variant: 1,
          accuracy: 2,
          hull: 2,
          speed: 2,
        },
        shipData: {
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
          shiny: true,
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
        },
        owner: user1.account.address,
      };

      // Construct the specific ship
      await ships.write.constructSpecificShip([1n, specificShip], {
        account: user1.account,
      });

      // Verify the ship was constructed with the specific attributes
      const constructedShipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const constructedShip = tupleToShip(constructedShipTuple);
      expect(constructedShip.name).to.equal("Custom Ship"); // name
      expect(constructedShip.traits.serialNumber).to.equal(0n); // traits.serialNumber should be 0
      expect(constructedShip.traits.variant).to.equal(1); // traits.variant
      expect(constructedShip.traits.accuracy).to.equal(2); // traits.accuracy
      expect(constructedShip.traits.hull).to.equal(2); // traits.hull
      expect(constructedShip.traits.speed).to.equal(2); // traits.speed
      expect(constructedShip.equipment.mainWeapon).to.equal(2); // equipment.mainWeapon
      expect(constructedShip.equipment.armor).to.equal(2); // equipment.armor
      expect(constructedShip.equipment.shields).to.equal(2); // equipment.shields
      expect(constructedShip.equipment.special).to.equal(2); // equipment.special
      expect(constructedShip.shipData.constructed).to.be.true; // shipData.constructed
      expect(constructedShip.shipData.shiny).to.be.true; // shipData.shiny
    });

    it("Should not allow unauthorized address to construct a specific ship", async function () {
      const { ships, user1, user2, owner } = await loadFixture(
        deployShipsFixture
      );

      // First authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create a ship first
      await ships.write.createShips([user1.account.address, 1n], {
        account: user1.account,
      });

      // Create a specific ship configuration
      const specificShip = {
        name: "Custom Ship",
        id: 1n,
        equipment: {
          mainWeapon: 2,
          armor: 2,
          shields: 2,
          special: 2,
        },
        traits: {
          serialNumber: 123n,
          colors: {
            h1: 200,
            s1: 40,
            l1: 47,
            h2: 180,
            s2: 50,
            l2: 60,
          },
          variant: 1,
          accuracy: 2,
          hull: 2,
          speed: 2,
        },
        shipData: {
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
          shiny: true,
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
        },
        owner: user1.account.address,
      };

      // Try to construct the specific ship as unauthorized user2
      await expect(
        ships.write.constructSpecificShip([1n, specificShip], {
          account: user2.account,
        })
      ).to.be.rejectedWith("NotAuthorized");
    });

    it("Should not allow constructing an already constructed ship", async function () {
      const { ships, user1, owner } = await loadFixture(deployShipsFixture);

      // First authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create a ship first
      await ships.write.createShips([user1.account.address, 1n], {
        account: user1.account,
      });

      // Create a specific ship configuration
      const specificShip = {
        name: "Custom Ship",
        id: 1n,
        equipment: {
          mainWeapon: 2,
          armor: 2,
          shields: 2,
          special: 2,
        },
        traits: {
          serialNumber: 123n,
          colors: {
            h1: 200,
            s1: 40,
            l1: 47,
            h2: 180,
            s2: 50,
            l2: 60,
          },
          variant: 1,
          accuracy: 2,
          hull: 2,
          speed: 2,
        },
        shipData: {
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
          shiny: true,
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
        },
        owner: user1.account.address,
      };

      // Construct the specific ship
      await ships.write.constructSpecificShip([1n, specificShip], {
        account: user1.account,
      });

      // Try to construct the same ship again
      await expect(
        ships.write.constructSpecificShip([1n, specificShip], {
          account: user1.account,
        })
      ).to.be.rejectedWith("ShipConstructed");
    });

    it("Should update ship cost after construction", async function () {
      const { ships, user1, owner } = await loadFixture(deployShipsFixture);

      // First authorize user1 to create ships
      await ships.write.setIsAllowedToCreateShips(
        [user1.account.address, true],
        {
          account: owner.account,
        }
      );

      // Create a ship first
      await ships.write.createShips([user1.account.address, 1n], {
        account: user1.account,
      });

      // Create a specific ship configuration
      const specificShip = {
        name: "Custom Ship",
        id: 1n,
        equipment: {
          mainWeapon: 2,
          armor: 2,
          shields: 2,
          special: 2,
        },
        traits: {
          serialNumber: 123n,
          colors: {
            h1: 200,
            s1: 40,
            l1: 47,
            h2: 180,
            s2: 50,
            l2: 60,
          },
          variant: 1,
          accuracy: 2,
          hull: 2,
          speed: 2,
        },
        shipData: {
          constructed: false,
          inFleet: false,
          timestampDestroyed: 0n,
          shiny: true,
          shipsDestroyed: 0,
          costsVersion: 1,
          cost: 0,
        },
        owner: user1.account.address,
      };

      // Construct the specific ship
      await ships.write.constructSpecificShip([1n, specificShip], {
        account: user1.account,
      });

      // Verify the ship cost was updated
      const constructedShipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const constructedShip = tupleToShip(constructedShipTuple);
      expect(constructedShip.shipData.cost).to.be.greaterThan(0); // shipData.cost should be set
    });
  });

  describe("Token-based Purchasing", function () {
    it("Should purchase tier 1 with UC tokens", async function () {
      const {
        ships,
        user1,
        user2,
        universalCredits,
        shipPurchaser,
        user1Purchaser,
      } = await loadFixture(deployShipsFixture);

      const initialBalance = await universalCredits.read.balanceOf([
        user1.account.address,
      ]);

      await user1Purchaser.write.purchaseWithUC([
        user1.account.address,
        0n,
        user2.account.address,
      ]);

      const finalBalance = await universalCredits.read.balanceOf([
        user1.account.address,
      ]);
      const shipCount = await ships.read.shipCount();

      // Check that 4.99 UC tokens were spent
      expect(initialBalance - finalBalance).to.equal(parseEther("4.99"));
      // Check that 5 ships were minted
      expect(shipCount).to.equal(5n);

      // Check all ships are owned by user1
      for (let i = 1; i <= 5; i++) {
        const shipTuple = (await ships.read.ships([BigInt(i)])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.owner.toString().toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }
    });

    it("Should process referral payment correctly with UC tokens", async function () {
      const {
        user1,
        user2,
        universalCredits,
        user1Purchaser,
        user2UC,
        shipPurchaser,
      } = await loadFixture(deployShipsFixture);

      const initialBalance = await universalCredits.read.balanceOf([
        user2.account.address,
      ]);

      await user1Purchaser.write.purchaseWithUC([
        user1.account.address,
        0n,
        user2.account.address,
      ]);

      const finalBalance = await universalCredits.read.balanceOf([
        user2.account.address,
      ]);

      // Check that referral received 1% of tier 1 price (4.99 UC)
      // For 4.99 UC, 1% is 0.0499 UC
      expect(finalBalance - initialBalance).to.equal(parseEther("0.0499"));

      // Check referral count
      const referralCount = await shipPurchaser.read.referralCount([
        user2.account.address,
      ]);
      expect(referralCount).to.equal(5n);
    });

    it("Should revert with insufficient UC balance", async function () {
      const { user1, user2, universalCredits, user1Purchaser } =
        await loadFixture(deployShipsFixture);

      // Burn all UC tokens from user1
      await universalCredits.write.transfer(
        ["0x000000000000000000000000000000000000dEaD", parseEther("1000")],
        {
          account: user1.account,
        }
      );

      await expect(
        user1Purchaser.write.purchaseWithUC([
          user1.account.address,
          0n,
          user2.account.address,
        ])
      ).to.be.rejectedWith("InsufficientFunds");
    });

    it("Should revert with zero address referral", async function () {
      const { user1, user1Purchaser } = await loadFixture(deployShipsFixture);

      await expect(
        user1Purchaser.write.purchaseWithUC([
          user1.account.address,
          0n,
          "0x0000000000000000000000000000000000000000",
        ])
      ).to.be.rejectedWith("InvalidReferral");
    });

    it("Should allow owner to update purchase info", async function () {
      const { shipPurchaser, owner } = await loadFixture(deployShipsFixture);

      const newTiers = [1, 2, 3];
      const newShipsPerTier = [5, 10, 15];
      const newPrices = [
        parseEther("5.99"),
        parseEther("10.99"),
        parseEther("15.99"),
      ];

      await shipPurchaser.write.setPurchaseInfo(
        [newTiers, newShipsPerTier, newPrices],
        {
          account: owner.account,
        }
      );

      const [tiers, shipsPerTier, prices] =
        await shipPurchaser.read.getPurchaseInfo();
      expect(tiers).to.deep.equal(newTiers);
      expect(shipsPerTier).to.deep.equal(newShipsPerTier);
      expect(prices).to.deep.equal(newPrices);
    });

    it("Should not allow non-owner to update purchase info", async function () {
      const { shipPurchaser, user1 } = await loadFixture(deployShipsFixture);

      const updatedTiers = [1, 2, 3];
      const updatedShipsPerTier = [5, 10, 15];
      const updatedPrices = [
        parseEther("5.99"),
        parseEther("10.99"),
        parseEther("15.99"),
      ];

      await expect(
        shipPurchaser.write.setPurchaseInfo(
          [updatedTiers, updatedShipsPerTier, updatedPrices],
          {
            account: user1.account,
          }
        )
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });

    it("Should allow owner to withdraw UC tokens", async function () {
      const { shipPurchaser, universalCredits, owner, user1 } =
        await loadFixture(deployShipsFixture);

      // Purchase some ships to get UC tokens in the contract
      await universalCredits.write.approve(
        [shipPurchaser.address, parseEther("100")],
        {
          account: user1.account,
        }
      );

      await shipPurchaser.write.purchaseWithUC(
        [user1.account.address, 0n, owner.account.address],
        {
          account: user1.account,
        }
      );

      const initialBalance = await universalCredits.read.balanceOf([
        owner.account.address,
      ]);
      await shipPurchaser.write.withdrawUC({ account: owner.account });
      const finalBalance = await universalCredits.read.balanceOf([
        owner.account.address,
      ]);

      expect(finalBalance > initialBalance).to.be.true;
    });

    it("Should not allow non-owner to withdraw UC tokens", async function () {
      const { shipPurchaser, user1 } = await loadFixture(deployShipsFixture);

      await expect(
        shipPurchaser.write.withdrawUC({ account: user1.account })
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });
  });

  describe("Recycle System", function () {
    it("Should allow owner to update recycle reward", async function () {
      const { ships, owner } = await loadFixture(deployShipsFixture);

      // Check initial reward
      expect(await ships.read.recycleReward()).to.equal(parseEther("0.1"));

      // Update reward
      await ships.write.setRecycleReward([parseEther("0.5")], {
        account: owner.account,
      });

      // Check new reward
      expect(await ships.read.recycleReward()).to.equal(parseEther("0.5"));
    });

    it("Should not allow non-owner to update recycle reward", async function () {
      const { ships, user1 } = await loadFixture(deployShipsFixture);

      await expect(
        ships.write.setRecycleReward([parseEther("0.5")], {
          account: user1.account,
        })
      ).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });

    it("Should allow users to recycle their ships and receive UC tokens", async function () {
      const { ships, universalCredits, user1, user2, shipPurchaser } =
        await loadFixture(deployShipsFixture);

      // Purchase some ships for user1 using tier 1 (gives 11 ships, enough to recycle)
      await universalCredits.write.approve(
        [shipPurchaser.address, parseEther("100")],
        {
          account: user1.account,
        }
      );

      await shipPurchaser.write.purchaseWithUC(
        [user1.account.address, 1n, user2.account.address],
        {
          account: user1.account,
        }
      );

      // Get initial UC balance
      const initialBalance = await universalCredits.read.balanceOf([
        user1.account.address,
      ]);

      // Get ship IDs owned by user1
      const shipIds = await ships.read.getShipIdsOwned([user1.account.address]);

      // Recycle all ships
      await ships.write.shipBreaker([shipIds], {
        account: user1.account,
      });

      // Check final UC balance (should have received 0.1 UC per ship)
      const finalBalance = await universalCredits.read.balanceOf([
        user1.account.address,
      ]);
      expect(finalBalance - initialBalance).to.equal(
        parseEther("0.1") * BigInt(shipIds.length)
      );

      // Verify ships are no longer owned by user1
      const remainingShips = await ships.read.getShipIdsOwned([
        user1.account.address,
      ]);
      expect(remainingShips.length).to.equal(0);
    });

    it("Should not allow recycling ships that are in a fleet", async function () {
      const { ships, universalCredits, user1, user2, shipPurchaser, owner } =
        await loadFixture(deployShipsFixture);

      // Set up game address first
      await ships.write.setConfig([
        owner.account.address, // gameAddress
        "0x0000000000000000000000000000000000000000", // lobbyAddress
        "0x0000000000000000000000000000000000000000", // fleetsAddress
        "0x0000000000000000000000000000000000000000", // shipGenerator
        "0x0000000000000000000000000000000000000000", // randomManager
        "0x0000000000000000000000000000000000000000", // metadataRenderer
      ]);

      // Purchase some ships for user1 using tier 1 (gives 11 ships, enough to recycle)
      await universalCredits.write.approve(
        [shipPurchaser.address, parseEther("100")],
        {
          account: user1.account,
        }
      );

      await shipPurchaser.write.purchaseWithUC(
        [user1.account.address, 1n, user2.account.address],
        {
          account: user1.account,
        }
      );

      // Get ship IDs owned by user1
      const shipIds = await ships.read.getShipIdsOwned([user1.account.address]);

      // Set a ship to be in fleet
      await ships.write.setInFleet([shipIds[0], true], {
        account: owner.account,
      });

      // Try to recycle ships
      await expect(
        ships.write.shipBreaker([shipIds], {
          account: user1.account,
        })
      ).to.be.rejectedWith("ShipInFleet");
    });

    it("Should not allow recycling ships owned by others", async function () {
      const { ships, universalCredits, user1, user2, shipPurchaser } =
        await loadFixture(deployShipsFixture);

      // Purchase some ships for user1 using tier 1 (gives 11 ships, enough to recycle)
      await universalCredits.write.approve(
        [shipPurchaser.address, parseEther("100")],
        {
          account: user1.account,
        }
      );

      await shipPurchaser.write.purchaseWithUC(
        [user1.account.address, 1n, user2.account.address],
        {
          account: user1.account,
        }
      );

      // Get ship IDs owned by user1
      const shipIds = await ships.read.getShipIdsOwned([user1.account.address]);

      // Try to recycle ships as user2
      await expect(
        ships.write.shipBreaker([shipIds], {
          account: user2.account,
        })
      ).to.be.rejectedWith("NotYourShip");
    });
  });

  describe("Flow-based Purchasing", function () {
    it("Should allow non-owner to purchase ships with Flow (tier 1)", async function () {
      const { ships, user1Ships, user1, user2, publicClient } =
        await loadFixture(deployShipsFixture);

      // Get initial ship count
      const initialShipCount = await ships.read.shipCount();

      // Non-owner (user1) purchases tier 1 with Flow using their contract instance
      await user1Ships.write.purchaseWithFlow(
        [user1.account.address, 1n, user2.account.address],
        { value: parseEther("9.99") }
      );

      // Verify ship count increased by 11 (tier 1 amount)
      const finalShipCount = await ships.read.shipCount();
      expect(finalShipCount - initialShipCount).to.equal(11n);

      // Verify all new ships are owned by user1
      for (let i = initialShipCount + 1n; i <= finalShipCount; i++) {
        const shipTuple = (await ships.read.ships([i])) as ShipTuple;
        const ship = tupleToShip(shipTuple);
        expect(ship.owner.toString().toLocaleLowerCase()).to.equal(
          user1.account.address.toLocaleLowerCase()
        );
      }

      // Verify user1 has now purchased enough ships to transfer
      const amountPurchased = await ships.read.amountPurchased([
        user1.account.address,
      ]);
      expect(Number(amountPurchased)).to.be.greaterThanOrEqual(10);
    });
  });
});
