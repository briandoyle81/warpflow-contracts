import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre from "hardhat";
import DeployModule from "../ignition/modules/DeployAndConfig";

describe("TutorialClaim", function () {
  async function deployTutorialFixture() {
    const [owner, user1, user2] = await hre.viem.getWalletClients();
    const deployed = await hre.ignition.deploy(DeployModule);

    const tutorialClaim = deployed.tutorialClaim;
    const user1TutorialClaim = await hre.viem.getContractAt(
      "TutorialClaim",
      tutorialClaim.address,
      { client: { wallet: user1 } }
    );
    const user2TutorialClaim = await hre.viem.getContractAt(
      "TutorialClaim",
      tutorialClaim.address,
      { client: { wallet: user2 } }
    );

    return {
      owner,
      user1,
      user2,
      ships: deployed.ships,
      gameResults: deployed.gameResults,
      tutorialClaim,
      user1TutorialClaim,
      user2TutorialClaim,
    };
  }

  /** Owner order from `getShipIdsOwned` is not guaranteed; key by name. */
  async function shipsByName(
    ships: Awaited<
      ReturnType<typeof deployTutorialFixture>
    >["ships"],
    owner: `0x${string}`
  ) {
    const shipIds = await ships.read.getShipIdsOwned([owner]);
    const out: Record<
      string,
      {
        name: string;
        equipment: {
          mainWeapon: number;
          armor: number;
          shields: number;
          special: number;
        };
      }
    > = {};
    for (const id of shipIds) {
      const s = await ships.read.getShip([id]);
      out[s.name] = {
        name: s.name,
        equipment: {
          mainWeapon: Number(s.equipment.mainWeapon),
          armor: Number(s.equipment.armor),
          shields: Number(s.equipment.shields),
          special: Number(s.equipment.special),
        },
      };
    }
    return out;
  }

  /** `playerStats` mapping returns `[wins, losses, totalGames]` from viem. */
  function expectStats(
    raw: readonly [bigint, bigint, bigint] | { wins: bigint; losses: bigint; totalGames: bigint },
    wins: bigint,
    losses: bigint,
    totalGames: bigint
  ) {
    const w = Array.isArray(raw)
      ? raw[0]
      : (raw as { wins: bigint }).wins;
    const l = Array.isArray(raw)
      ? raw[1]
      : (raw as { losses: bigint }).losses;
    const t = Array.isArray(raw)
      ? raw[2]
      : (raw as { totalGames: bigint }).totalGames;
    expect(w).to.equal(wins);
    expect(l).to.equal(losses);
    expect(t).to.equal(totalGames);
  }

  it("completes win path once, mints 2 ships, records win", async function () {
    const { user1, ships, gameResults, user1TutorialClaim, tutorialClaim } =
      await loadFixture(deployTutorialFixture);

    await user1TutorialClaim.write.completeTutorialWinPath();

    const completed = await tutorialClaim.read.tutorialCompleted([
      user1.account.address,
    ]);
    expect(completed).to.equal(true);

    const shipIds = await ships.read.getShipIdsOwned([user1.account.address]);
    expect(shipIds.length).to.equal(2);

    const byName = await shipsByName(ships, user1.account.address);
    expect(Object.keys(byName).sort()).to.deep.equal(
      ["Sentinel", "Vigilant"].sort()
    );

    const vigilant = byName["Vigilant"];
    const sentinel = byName["Sentinel"];
    expect(vigilant.equipment.mainWeapon).to.equal(1); // Railgun
    expect(vigilant.equipment.armor).to.equal(2); // Medium
    expect(vigilant.equipment.shields).to.equal(2);
    expect(vigilant.equipment.special).to.equal(2); // Repair

    expect(sentinel.equipment.mainWeapon).to.equal(0); // Laser
    expect(sentinel.equipment.armor).to.equal(1); // Light
    expect(sentinel.equipment.shields).to.equal(1);
    expect(sentinel.equipment.special).to.equal(0); // None

    const stats = await gameResults.read.playerStats([user1.account.address]);
    expectStats(stats, 1n, 0n, 1n);
  });

  it("completes loss path once, mints 3 ships, records loss", async function () {
    const { user1, ships, gameResults, user1TutorialClaim } =
      await loadFixture(deployTutorialFixture);

    await user1TutorialClaim.write.completeTutorialLossPath();

    const shipIds = await ships.read.getShipIdsOwned([user1.account.address]);
    expect(shipIds.length).to.equal(3);

    const byName = await shipsByName(ships, user1.account.address);
    expect(Object.keys(byName).sort()).to.deep.equal(
      ["Resolute", "Sentinel", "Vigilant"].sort()
    );

    const stats = await gameResults.read.playerStats([user1.account.address]);
    expectStats(stats, 0n, 1n, 1n);
  });

  it("reverts on second tutorial completion for same address", async function () {
    const { user1TutorialClaim } = await loadFixture(deployTutorialFixture);

    await user1TutorialClaim.write.completeTutorialWinPath();
    await expect(
      user1TutorialClaim.write.completeTutorialLossPath()
    ).to.be.rejectedWith("TutorialAlreadyCompleted");
  });

  it("allows different addresses to complete independently", async function () {
    const { user1, user2, gameResults, user1TutorialClaim, user2TutorialClaim } =
      await loadFixture(deployTutorialFixture);

    await user1TutorialClaim.write.completeTutorialWinPath();
    await user2TutorialClaim.write.completeTutorialLossPath();

    const s1 = await gameResults.read.playerStats([user1.account.address]);
    expectStats(s1, 1n, 0n, 1n);

    const s2 = await gameResults.read.playerStats([user2.account.address]);
    expectStats(s2, 0n, 1n, 1n);
  });

  /**
   * Real `GameResults` from Ignition does not callback into `TutorialClaim`.
   * This case uses a malicious stand-in for `addWin` only.
   */
  it("blocks reentrant callback from game results contract", async function () {
    const [deployer, user1] = await hre.viem.getWalletClients();
    const ships = await hre.viem.deployContract("MockTutorialShips", []);
    const reentrantResults = await hre.viem.deployContract(
      "MockTutorialReentrantGameResults",
      []
    );
    const tutorialClaim = await hre.viem.deployContract("TutorialClaim", [
      ships.address,
      reentrantResults.address,
    ]);
    await reentrantResults.write.setTarget([tutorialClaim.address], {
      account: deployer.account.address,
    });

    const user1TutorialClaim = await hre.viem.getContractAt(
      "TutorialClaim",
      tutorialClaim.address,
      { client: { wallet: user1 } }
    );

    await expect(
      user1TutorialClaim.write.completeTutorialWinPath()
    ).to.be.rejected;
  });

  it("rejects direct createSpecificShip from unauthorized EOA", async function () {
    const { user1, ships } = await loadFixture(deployTutorialFixture);

    const user1Ships = await hre.viem.getContractAt("Ships", ships.address, {
      client: { wallet: user1 },
    });

    const template = {
      name: "Unauthorized",
      id: 0n,
      equipment: {
        mainWeapon: 0,
        armor: 1,
        shields: 1,
        special: 0,
      },
      traits: {
        serialNumber: 0n,
        colors: {
          h1: 10,
          s1: 10,
          l1: 10,
          h2: 20,
          s2: 20,
          l2: 20,
          h3: 0,
          s3: 0,
          l3: 0,
        },
        variant: 1,
        accuracy: 1,
        hull: 1,
        speed: 1,
      },
      shipData: {
        shipsDestroyed: 0,
        costsVersion: 0,
        cost: 0,
        modified: 0,
        shiny: false,
        constructed: false,
        inFleet: false,
        isFreeShip: false,
        timestampDestroyed: 0n,
      },
      owner: user1.account.address,
    } as const;

    await expect(
      user1Ships.write.createSpecificShip([user1.account.address, template])
    ).to.be.rejectedWith("NotAuthorized");
  });
});
