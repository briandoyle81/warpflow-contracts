// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

const DeployModule = buildModule("DeployModule", (m) => {
  // Deploy helper contracts first
  const randomManager = m.contract("RandomManager");

  // Deploy all sub-renderers
  const renderSpecial1 = m.contract("RenderSpecial1");
  const renderSpecial2 = m.contract("RenderSpecial2");
  const renderSpecial3 = m.contract("RenderSpecial3");

  const renderAft0 = m.contract("RenderAft0");
  const renderAft1 = m.contract("RenderAft1");
  const renderAft2 = m.contract("RenderAft2");

  const renderWeapon1 = m.contract("RenderWeapon1");
  const renderWeapon2 = m.contract("RenderWeapon2");
  const renderWeapon3 = m.contract("RenderWeapon3");
  const renderWeapon4 = m.contract("RenderWeapon4");

  const renderFore0 = m.contract("RenderFore0");
  const renderFore1 = m.contract("RenderFore1");
  const renderFore2 = m.contract("RenderFore2");
  const renderForePerfect = m.contract("RenderForePerfect");
  const renderShield1 = m.contract("RenderShield1");
  const renderShield2 = m.contract("RenderShield2");
  const renderShield3 = m.contract("RenderShield3");

  const renderArmor1 = m.contract("RenderArmor1");
  const renderArmor2 = m.contract("RenderArmor2");
  const renderArmor3 = m.contract("RenderArmor3");

  const renderBaseBody = m.contract("RenderBaseBody");

  // Deploy main renderers that combine sub-renderers
  const renderSpecial = m.contract("RenderSpecial", [
    [renderSpecial1, renderSpecial2, renderSpecial3],
  ]);

  const renderAft = m.contract("RenderAft", [
    [renderAft0, renderAft1, renderAft2],
  ]);

  const renderWeapon = m.contract("RenderWeapon", [
    [renderWeapon1, renderWeapon2, renderWeapon3, renderWeapon4],
  ]);

  const renderBody = m.contract("RenderBody", [
    [
      renderBaseBody,
      renderShield1,
      renderShield2,
      renderShield3,
      renderArmor1,
      renderArmor2,
      renderArmor3,
    ],
  ]);

  const renderFore = m.contract("RenderFore", [
    [renderFore0, renderFore1, renderFore2, renderForePerfect],
  ]);

  // Deploy ImageRenderer with all main renderers
  const imageRenderer = m.contract("ImageRenderer", [
    renderSpecial,
    renderAft,
    renderWeapon,
    renderBody,
    renderFore,
  ]);

  // Deploy MetadataRenderer with ImageRenderer
  const metadataRenderer = m.contract("RenderMetadata", [imageRenderer]);

  // Deploy mock ship names
  const shipNames = m.contract("MockOnchainRandomShipNames");

  // For testnet use
  // const shipNames = "0x9E433A07D283d56E8243EA25b7358521b1922df5";

  // Deploy GenerateNewShip with ship names
  const generateNewShip = m.contract("GenerateNewShip", [shipNames]);

  // Deploy UniversalCredits token
  const universalCredits = m.contract("UniversalCredits");

  // Finally deploy Ships with all dependencies
  const ships = m.contract("Ships", [metadataRenderer]);

  // Deploy ShipAttributes contract
  const shipAttributes = m.contract("ShipAttributes", [ships]);

  // Deploy ShipPurchaser
  const shipPurchaser = m.contract("ShipPurchaser", [ships, universalCredits]);

  // Deploy Maps contract
  const maps = m.contract("Maps");

  // Deploy GameResults contract
  const gameResults = m.contract("GameResults");

  // Deploy Game contract with ShipAttributes
  const game = m.contract("Game", [ships, shipAttributes]);

  // Deploy Fleets contract
  const fleets = m.contract("Fleets", [ships]);

  // Deploy Lobbies contract
  const lobbies = m.contract("Lobbies", [ships]);

  // Set all config values in a single call
  m.call(ships, "setConfig", [
    game, // gameAddress
    lobbies, // lobbyAddress
    fleets, // fleetsAddress
    generateNewShip,
    randomManager,
    metadataRenderer,
  ]);

  // Set Lobbies address in Game contract
  m.call(game, "setLobbiesAddress", [lobbies]);

  // Set Fleets address in Game contract
  m.call(game, "setFleetsAddress", [fleets]);

  // Set Maps address in Game contract
  m.call(game, "setMapsAddress", [maps]);

  // Set GameResults address in Game contract
  m.call(game, "setGameResultsAddress", [gameResults]);

  // Set Game address in Maps contract
  m.call(maps, "setGameAddress", [game]);

  // Set Game address in Lobbies contract
  m.call(lobbies, "setGameAddress", [game]);

  // Set Fleets address in Lobbies contract
  m.call(lobbies, "setFleetsAddress", [fleets]);

  // Set Lobbies address in Fleets contract
  m.call(fleets, "setLobbiesAddress", [lobbies]);

  // Set Game address in Fleets contract
  m.call(fleets, "setGameAddress", [game]);

  // Allow ShipPurchaser to create ships
  m.call(ships, "setIsAllowedToCreateShips", [shipPurchaser, true]);

  // Enable minting for UniversalCredits
  m.call(universalCredits, "setMintIsActive", [true]);

  // Allow ShipPurchaser and Ships to mint UniversalCredits
  m.call(universalCredits, "setAuthorizedToMint", [shipPurchaser, true], {
    id: "AuthorizeShipPurchaserToMint",
  });
  m.call(universalCredits, "setAuthorizedToMint", [ships, true], {
    id: "AuthorizeShipsToMint",
  });

  // Set UniversalCredits address in Ships contract
  m.call(ships, "setUniversalCredits", [universalCredits]);

  // WARNING: This works for deploying but breaks the tests for some reason.
  // Purchase tier 4 for the deployer
  // m.call(
  //   ships,
  //   "purchaseWithFlow",
  //   [
  //     "0x69a5B3aE8598fC5A5419eaa1f2A59Db2D052e346",
  //     4,
  //     "0x69a5B3aE8598fC5A5419eaa1f2A59Db2D052e346",
  //   ],
  //   { value: parseEther("99.99") }
  // );

  // m.call(ships, "constructAllMyShips");

  return {
    randomManager,
    renderSpecial1,
    renderSpecial2,
    renderSpecial3,
    renderAft0,
    renderAft1,
    renderAft2,
    renderWeapon1,
    renderWeapon2,
    renderWeapon3,
    renderWeapon4,
    renderShield1,
    renderShield2,
    renderShield3,
    renderArmor1,
    renderArmor2,
    renderArmor3,
    renderFore0,
    renderFore1,
    renderFore2,
    renderForePerfect,
    renderSpecial,
    renderAft,
    renderWeapon,
    renderBody,
    renderFore,
    imageRenderer,
    metadataRenderer,
    shipNames,
    generateNewShip,
    ships,
    shipAttributes,
    universalCredits,
    shipPurchaser,
    maps,
    gameResults,
    game,
    fleets,
    lobbies,
  };
});

export default DeployModule;
