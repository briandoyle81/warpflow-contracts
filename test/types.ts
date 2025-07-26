import { Address } from "viem";

export interface Ship {
  name: string;
  id: bigint;
  equipment: ShipEquipment;
  traits: ShipTraits;
  shipData: ShipData;
  owner: Address;
}

export interface ShipEquipment {
  mainWeapon: number;
  armor: number;
  shields: number;
  special: number;
}

export interface ShipTraits {
  serialNumber: bigint;
  colors: ShipColors;
  variant: number;
  accuracy: number;
  hull: number;
  speed: number;
}

export interface ShipColors {
  h1: number;
  s1: number;
  l1: number;
  h2: number;
  s2: number;
  l2: number;
}

export interface ShipData {
  shipsDestroyed: number;
  costsVersion: number;
  cost: number;
  shiny: boolean;
  constructed: boolean;
  inFleet: boolean;
  timestampDestroyed: bigint;
}

export type ShipTuple = [
  string, // name
  bigint, // id
  ShipEquipment, // equipment
  ShipTraits, // traits
  ShipData, // shipData
  Address // owner
];

export function tupleToShip(tuple: ShipTuple): Ship {
  return {
    name: tuple[0],
    id: tuple[1],
    equipment: tuple[2],
    traits: tuple[3],
    shipData: tuple[4],
    owner: tuple[5],
  };
}

// New types for Game and Lobbies contracts

export enum LobbyStatus {
  Open,
  FleetSelection,
  InGame,
}

export interface Lobby {
  id: bigint;
  creator: Address;
  joiner: Address;
  costLimit: bigint;
  status: LobbyStatus;
  createdAt: bigint;
  gameStartedAt: bigint;
  creatorFleetId: bigint;
  joinerFleetId: bigint;
  creatorGoesFirst: boolean;
  turnTime: bigint;
  joinedAt: bigint;
  joinerFleetSetAt: bigint;
}

export interface Fleet {
  id: bigint;
  lobbyId: bigint;
  owner: Address;
  shipIds: bigint[];
  totalCost: bigint;
  isComplete: boolean;
}

export interface PlayerLobbyState {
  activeLobbyId: bigint;
  activeLobbiesCount: bigint;
  hasActiveLobby: boolean;
  kickCount: bigint;
  lastKickTime: bigint;
}

export interface Attributes {
  version: number;
  range: number;
  gunDamage: number;
  hullPoints: number;
  movement: number;
  statusEffects: number[];
}

export interface GameData {
  gameId: bigint;
  lobbyId: bigint;
  creator: Address;
  joiner: Address;
  creatorFleetId: bigint;
  joinerFleetId: bigint;
  creatorGoesFirst: boolean;
  startedAt: bigint;
  currentTurn: Address;
}

// Tuple types for contract return values
export type LobbyTuple = [
  bigint, // id
  Address, // creator
  Address, // joiner
  bigint, // costLimit
  number, // status
  bigint, // createdAt
  bigint, // gameStartedAt
  bigint, // creatorFleetId
  bigint, // joinerFleetId
  boolean, // creatorGoesFirst
  bigint, // turnTime
  bigint, // joinedAt
  bigint // joinerFleetSetAt
];

export type FleetTuple = [
  bigint, // id
  bigint, // lobbyId
  Address, // owner
  bigint[], // shipIds
  bigint, // totalCost
  boolean // isComplete
];

export type PlayerLobbyStateTuple = [
  bigint, // activeLobbyId
  bigint, // activeLobbiesCount
  boolean, // hasActiveLobby
  bigint, // kickCount
  bigint // lastKickTime
];

export type GameDataTuple = [
  bigint, // gameId
  bigint, // lobbyId
  Address, // creator
  Address, // joiner
  bigint, // creatorFleetId
  bigint, // joinerFleetId
  boolean, // creatorGoesFirst
  bigint, // startedAt
  Address // currentTurn
];

// Helper functions to convert tuples to objects
export function tupleToLobby(tuple: LobbyTuple): Lobby {
  return {
    id: tuple[0],
    creator: tuple[1],
    joiner: tuple[2],
    costLimit: tuple[3],
    status: tuple[4],
    createdAt: tuple[5],
    gameStartedAt: tuple[6],
    creatorFleetId: tuple[7],
    joinerFleetId: tuple[8],
    creatorGoesFirst: tuple[9],
    turnTime: tuple[10],
    joinedAt: tuple[11],
    joinerFleetSetAt: tuple[12],
  };
}

export function tupleToFleet(tuple: FleetTuple): Fleet {
  return {
    id: tuple[0],
    lobbyId: tuple[1],
    owner: tuple[2],
    shipIds: tuple[3],
    totalCost: tuple[4],
    isComplete: tuple[5],
  };
}

export function tupleToPlayerLobbyState(
  tuple: PlayerLobbyStateTuple
): PlayerLobbyState {
  return {
    activeLobbyId: tuple[0],
    activeLobbiesCount: tuple[1],
    hasActiveLobby: tuple[2],
    kickCount: tuple[3],
    lastKickTime: tuple[4],
  };
}

export function tupleToGameData(tuple: GameDataTuple): GameData {
  return {
    gameId: tuple[0],
    lobbyId: tuple[1],
    creator: tuple[2],
    joiner: tuple[3],
    creatorFleetId: tuple[4],
    joinerFleetId: tuple[5],
    creatorGoesFirst: tuple[6],
    startedAt: tuple[7],
    currentTurn: tuple[8],
  };
}

export interface Position {
  row: number; // Row position (0 to gridHeight-1)
  col: number; // Column position (0 to gridWidth-1)
}

export interface ShipPosition {
  shipId: bigint;
  position: Position;
  isCreator: boolean;
}

export interface GameDataView {
  gameId: bigint;
  lobbyId: bigint;
  creator: string;
  joiner: string;
  creatorFleetId: bigint;
  joinerFleetId: bigint;
  creatorGoesFirst: boolean;
  startedAt: bigint;
  currentTurn: string;
  shipAttributes: Attributes[]; // Combined array of all ship attributes indexed by ship ID
  shipPositions: ShipPosition[]; // All ship positions on the grid
  gridWidth: number;
  gridHeight: number;
}

export enum ActionType {
  Pass,
  Shoot,
}
