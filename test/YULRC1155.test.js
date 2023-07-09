const path = require("path");
const fs = require("fs");
const { getYULRC1155Bytecode } = require("./utils");
const {
  loadFixture,
  getStorageAt,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const URI = "https://token-cdn-domain/{id}.json";
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const DATA = "0x12345678";

/**
 * Fixture: Deploys `YULRC1155` contract from its abi and bytecode.
 */
async function deployYULRC1155Fixture() {
  const yulrc1155Abi = fs.readFileSync(
    path.resolve(__dirname, "..", "contracts", "YULRC1155.abi.json"),
    "utf8"
  );
  const yulrc1155Bytecode = await getYULRC1155Bytecode();
  const YULRC1155 = await ethers.getContractFactory(
    JSON.parse(yulrc1155Abi),
    yulrc1155Bytecode
  );
  const yulrc1155Contract = await YULRC1155.deploy(URI);

  return { yulrc1155Contract };
}

/**
 * Fixture: Deploys ERC1155Receiver `UnexpectedValue` contract.
 */
async function deployUnexpectedValueFixture() {
  const UnexpectedValue = await ethers.getContractFactory("UnexpectedValue");
  const unexpectedValueContract = await UnexpectedValue.deploy();

  return { unexpectedValueContract };
}
async function deployUnexpectedValueFixtureTwo() {
  const UnexpectedValue = await ethers.getContractFactory("UnexpectedValue");
  const unexpectedValueContract = await UnexpectedValue.deploy();

  return { unexpectedValueContract };
}

/**
 * Fixture: Deploys `ReceiverReverts` contract.
 */
async function deployReceiverRevertsFixture() {
  const ReceiverReverts = await ethers.getContractFactory("ReceiverReverts");
  const receiverRevertsContract = await ReceiverReverts.deploy();

  return { receiverRevertsContract };
}
async function deployReceiverRevertsFixtureTwo() {
  const ReceiverReverts = await ethers.getContractFactory("ReceiverReverts");
  const receiverRevertsContract = await ReceiverReverts.deploy();

  return { receiverRevertsContract };
}

/**
 * Fixture: Deploys `MissingFunction` contract.
 */
async function deployMissingFunctionFixture() {
  const MissingFunction = await ethers.getContractFactory("MissingFunction");
  const missingFunctionContract = await MissingFunction.deploy();

  return { missingFunctionContract };
}
async function deployMissingFunctionFixtureTwo() {
  const MissingFunction = await ethers.getContractFactory("MissingFunction");
  const missingFunctionContract = await MissingFunction.deploy();

  return { missingFunctionContract };
}

/**
 * Fixture: Deploys `RevertsOnSingleTransfers` contract.
 */
async function deployRevertsOnSingleTransfers() {
  const RevertsOnSingleTransfers = await ethers.getContractFactory(
    "RevertsOnSingleTransfers"
  );
  const revertsOnSingleTransfersContract =
    await RevertsOnSingleTransfers.deploy();

  return { revertsOnSingleTransfersContract };
}

/**
 * Fixture: Deploys `ERC1155Receiver` contract.
 */
async function deployERC1155ReceiverFixture() {
  const ERC1155Receiver = await ethers.getContractFactory("ERC1155Receiver");
  const erc1155ReceiverContract = await ERC1155Receiver.deploy();

  return { erc1155ReceiverContract };
}
// Hack: separate fixture function needed to avoid `FixtureSnapshotError` bug
async function deployERC1155ReceiverFixtureTwo() {
  const ERC1155Receiver = await ethers.getContractFactory("ERC1155Receiver");
  const erc1155ReceiverContract = await ERC1155Receiver.deploy();

  return { erc1155ReceiverContract };
}
async function deployERC1155ReceiverFixtureThree() {
  const ERC1155Receiver = await ethers.getContractFactory("ERC1155Receiver");
  const erc1155ReceiverContract = await ERC1155Receiver.deploy();

  return { erc1155ReceiverContract };
}
async function deployERC1155ReceiverFixtureFour() {
  const ERC1155Receiver = await ethers.getContractFactory("ERC1155Receiver");
  const erc1155ReceiverContract = await ERC1155Receiver.deploy();

  return { erc1155ReceiverContract };
}

/**
 * YULRC1155
 *
 * describes:
 * - balanceOf
 * - uri
 * - balanceOfBatch
 * - setApprovalForAll/isApprovedForAll
 * - safeTransferFrom
 * - safeBatchTransferFrom
 * - mint
 * - mintBatch
 * - burn
 * - burnBatch
 */
describe("YULRC1155", function () {
  /**
   * balanceOf(address account, uint256 id)
   *
   * it:
   * - should revert when querying with the zero address
   * - should return zero for addresses with no tokens
   * - should return the balance of tokens owned by the given address
   */

  describe("balanceOf", function () {
    const tokenId = 1990;
    const mintAmount = 9001;

    it("should revert when querying with the zero address", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);

      await expect(yulrc1155Contract.balanceOf(ZERO_ADDRESS, tokenId)).to.be
        .reverted;
    });

    it("should return zero for addresses with no tokens", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, nonTokenHolder] = await ethers.getSigners();

      expect(
        await yulrc1155Contract.balanceOf(nonTokenHolder.address, tokenId)
      ).to.equal(0);
    });

    it("should return the balance of tokens owned by the given address", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(mintAmount);
    });
  });
});
