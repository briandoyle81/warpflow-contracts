import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import { parseEther, zeroAddress } from "viem";
import DeployModule from "../ignition/modules/DeployAndConfig";
import { deployShipsFixture } from "./fixtures/deployShipsFixture";
import { ShipTuple, tupleToShip } from "./types";

/** Same Ignition module as Ships tests; builds lobby + constructed free ships for fleet rules. */
async function deployLobbyFleetFixture() {
  const [owner, creator, joiner] = await hre.viem.getWalletClients();
  const publicClient = await hre.viem.getPublicClient();
  const deployed = await hre.ignition.deploy(DeployModule);

  const ships = deployed.ships;
  const randomManager = deployed.randomManager;
  const shipAttributes = deployed.shipAttributes;

  const creatorLobbies = await hre.viem.getContractAt(
    "Lobbies",
    deployed.lobbies.address,
    { client: { wallet: creator } },
  );
  const joinerLobbies = await hre.viem.getContractAt(
    "Lobbies",
    deployed.lobbies.address,
    { client: { wallet: joiner } },
  );

  await ships.write.claimFreeShips([1], { account: creator.account });
  await ships.write.claimFreeShips([1], { account: joiner.account });

  const fulfillRandomnessForPlayer = async (address: `0x${string}`) => {
    const shipIds = await ships.read.getShipIdsOwned([address]);
    for (const shipId of shipIds) {
      const shipTuple = (await ships.read.ships([shipId])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      await randomManager.write.fulfillRandomRequest([ship.traits.serialNumber]);
    }
    return shipIds;
  };

  await fulfillRandomnessForPlayer(creator.account.address);
  await fulfillRandomnessForPlayer(joiner.account.address);

  await ships.write.constructAllMyShips({ account: creator.account });
  await ships.write.constructAllMyShips({ account: joiner.account });

  const creatorShipIds = await ships.read.getShipIdsOwned([
    creator.account.address,
  ]);

  return {
    owner,
    creator,
    joiner,
    publicClient,
    ships,
    shipAttributes,
    creatorLobbies,
    joinerLobbies,
    creatorShipIds,
  };
}

function sampleCostsV2() {
  return {
    version: 2,
    baseCost: 60,
    accuracy: [0, 15, 30],
    hull: [0, 15, 30],
    speed: [0, 15, 30],
    mainWeapon: [30, 35, 45, 45],
    armor: [0, 8, 12, 18],
    shields: [0, 12, 24, 36],
    special: [0, 12, 24, 18],
  };
}

function sampleSetAllAttributesArgs() {
  const newGuns = [
    { range: 8, damage: 30, movement: 0 },
    { range: 15, damage: 25, movement: 0 },
    { range: 10, damage: 35, movement: -1 },
    { range: 5, damage: 45, movement: 0 },
  ];
  const newArmors = [
    { damageReduction: 0, movement: 1 },
    { damageReduction: 5, movement: 0 },
    { damageReduction: 10, movement: -1 },
    { damageReduction: 15, movement: -2 },
  ];
  const newShields = [
    { damageReduction: 0, movement: 1 },
    { damageReduction: 8, movement: 0 },
    { damageReduction: 15, movement: -1 },
    { damageReduction: 25, movement: -2 },
  ];
  const newSpecials = [
    { range: 0, strength: 0, movement: 0 },
    { range: 6, strength: 10, movement: 0 },
    { range: 8, strength: 0, movement: 0 },
    { range: 4, strength: 15, movement: 0 },
  ];
  const newForeAccuracy = [0, 130, 160];
  const newEngineSpeeds = [0, 2, 3];
  const newHull = [0, 10, 20];
  return {
    newGuns,
    newArmors,
    newShields,
    newSpecials,
    newForeAccuracy,
    newEngineSpeeds,
    newHull,
  };
}

describe("Ship costs, versions, and fleets", function () {
  describe("ShipAttributes — current version pointer", function () {
    it("lets owner setCurrentAttributesVersion back to a prior version", async function () {
      const { shipAttributes, owner } = await loadFixture(deployShipsFixture);

      expect(
        await shipAttributes.read.getCurrentAttributesVersion(),
      ).to.equal(1);

      const {
        newGuns,
        newArmors,
        newShields,
        newSpecials,
        newForeAccuracy,
        newEngineSpeeds,
        newHull,
      } = sampleSetAllAttributesArgs();

      await shipAttributes.write.setAllAttributes(
        [
          120,
          4,
          newGuns,
          newArmors,
          newShields,
          newSpecials,
          newForeAccuracy,
          newHull,
          newEngineSpeeds,
        ],
        { account: owner.account },
      );

      expect(
        await shipAttributes.read.getCurrentAttributesVersion(),
      ).to.equal(2);

      await shipAttributes.write.setCurrentAttributesVersion([1n], {
        account: owner.account,
      });

      expect(
        await shipAttributes.read.getCurrentAttributesVersion(),
      ).to.equal(1);

      const v1 = await shipAttributes.read.getAttributesVersionBase([1n]);
      expect(v1[0]).to.equal(1);
      expect(v1[1]).to.equal(100);

      const v2 = await shipAttributes.read.getAttributesVersionBase([2n]);
      expect(v2[0]).to.equal(2);
      expect(v2[1]).to.equal(120);
    });
  });

  describe("Ships.setCostOfShip", function () {
    it("rejects non-owner non-game callers", async function () {
      const { ships, user1, randomManager } =
        await loadFixture(deployShipsFixture);

      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user1.account.address, 1],
        { value: parseEther("4.99") },
      );

      const shipTuple = (await ships.read.ships([1n])) as ShipTuple;
      const ship = tupleToShip(shipTuple);
      await randomManager.write.fulfillRandomRequest([ship.traits.serialNumber]);
      await ships.write.constructShip([1n], { account: user1.account });

      await expect(
        ships.write.setCostOfShip([1n], { account: user1.account }),
      ).to.be.rejectedWith("NotAuthorized");
    });

    it("after setCosts, owner syncs ship cost and costsVersion to match live tables", async function () {
      const { ships, shipAttributes, owner, user1, randomManager } =
        await loadFixture(deployShipsFixture);

      await ships.write.purchaseWithFlow(
        [user1.account.address, 0n, user1.account.address, 1],
        { value: parseEther("4.99") },
      );

      const shipTupleBefore = (await ships.read.ships([1n])) as ShipTuple;
      const s0 = tupleToShip(shipTupleBefore);
      await randomManager.write.fulfillRandomRequest([s0.traits.serialNumber]);
      await ships.write.constructShip([1n], { account: user1.account });

      const vBefore = await shipAttributes.read.getCurrentCostsVersion();
      const shipBefore = tupleToShip(
        (await ships.read.ships([1n])) as ShipTuple,
      );
      expect(Number(shipBefore.shipData.costsVersion)).to.equal(
        Number(vBefore),
      );

      await shipAttributes.write.setCosts([sampleCostsV2()], {
        account: owner.account,
      });

      const vAfter = await shipAttributes.read.getCurrentCostsVersion();
      expect(Number(vAfter)).to.equal(2);

      const stale = tupleToShip((await ships.read.ships([1n])) as ShipTuple);
      expect(stale.shipData.costsVersion).to.equal(vBefore);

      await ships.write.setCostOfShip([1n], { account: owner.account });

      const shipMem = await ships.read.getShip([1n]);
      const expectedCost =
        await shipAttributes.read.calculateShipCost([shipMem]);

      const updated = tupleToShip((await ships.read.ships([1n])) as ShipTuple);
      expect(Number(updated.shipData.costsVersion)).to.equal(Number(vAfter));
      expect(BigInt(updated.shipData.cost)).to.equal(BigInt(expectedCost));
    });

    it("reverts ShipInFleet while ship is in a lobby fleet", async function () {
      const {
        owner,
        creator,
        joiner,
        ships,
        shipAttributes,
        creatorLobbies,
        joinerLobbies,
        creatorShipIds,
      } = await loadFixture(deployLobbyFleetFixture);

      const costLimit = 1000n;
      const turnTime = 300n;

      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        true,
        0n,
        100n,
        zeroAddress,
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      const shipId = creatorShipIds[0];
      await creatorLobbies.write.createFleet([
        1n,
        [shipId],
        [{ row: 0, col: 0 }],
      ]);

      await expect(
        ships.write.setCostOfShip([shipId], { account: owner.account }),
      ).to.be.rejectedWith("ShipInFleet");

      await shipAttributes.write.setCosts([sampleCostsV2()], {
        account: owner.account,
      });

      await expect(
        ships.write.setCostOfShip([shipId], { account: owner.account }),
      ).to.be.rejectedWith("ShipInFleet");
    });

    it("allows setCostOfShip after creator fleet is cleared (creator leaves)", async function () {
      const {
        owner,
        creator,
        joiner,
        ships,
        shipAttributes,
        creatorLobbies,
        joinerLobbies,
        creatorShipIds,
      } = await loadFixture(deployLobbyFleetFixture);

      const costLimit = 1000n;
      const turnTime = 300n;

      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        true,
        0n,
        100n,
        zeroAddress,
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      const shipId = creatorShipIds[0];
      await creatorLobbies.write.createFleet([
        1n,
        [shipId],
        [{ row: 0, col: 0 }],
      ]);

      await creatorLobbies.write.leaveLobby([1n]);

      await shipAttributes.write.setCosts([sampleCostsV2()], {
        account: owner.account,
      });

      await ships.write.setCostOfShip([shipId], { account: owner.account });

      const v = await shipAttributes.read.getCurrentCostsVersion();
      const updated = tupleToShip((await ships.read.ships([shipId])) as ShipTuple);
      expect(Number(updated.shipData.costsVersion)).to.equal(Number(v));

      const shipMem = await ships.read.getShip([shipId]);
      const expectedCost =
        await shipAttributes.read.calculateShipCost([shipMem]);
      expect(BigInt(updated.shipData.cost)).to.equal(BigInt(expectedCost));
    });
  });

  describe("Fleets cost version guard", function () {
    it("reverts createFleet with ShipCostVersionMismatch when ship lags global costs version", async function () {
      const {
        owner,
        creator,
        joiner,
        ships,
        shipAttributes,
        creatorLobbies,
        joinerLobbies,
        creatorShipIds,
      } = await loadFixture(deployLobbyFleetFixture);

      await shipAttributes.write.setCosts([sampleCostsV2()], {
        account: owner.account,
      });

      const costLimit = 1000n;
      const turnTime = 300n;

      await creatorLobbies.write.createLobby([
        costLimit,
        turnTime,
        true,
        0n,
        100n,
        zeroAddress,
      ]);
      await joinerLobbies.write.joinLobby([1n]);

      const shipId = creatorShipIds[0];

      await expect(
        creatorLobbies.write.createFleet([
          1n,
          [shipId],
          [{ row: 0, col: 0 }],
        ]),
      ).to.be.rejectedWith("ShipCostVersionMismatch");

      await ships.write.setCostOfShip([shipId], { account: owner.account });

      await creatorLobbies.write.createFleet([
        1n,
        [shipId],
        [{ row: 0, col: 0 }],
      ]);
    });
  });
});
