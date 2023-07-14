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

  /**
   * URI(uint256)
   *
   * it:
   * - should set the initial URI for all token types
   */
  describe("uri", function () {
    const tokenIdOne = 1001;
    const tokenIdTwo = 2002;

    it("should set the initial URI for all token types", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);

      expect(await yulrc1155Contract.uri(tokenIdOne)).to.be.equal(URI);
      expect(await yulrc1155Contract.uri(tokenIdTwo)).to.be.equal(URI);
    });
  });

  /**
   * setApprovalForAll(address operator, bool approved)
   * isApprovedForAll(address account, address operator)
   *
   * it:
   * - should revert if attempting to approve self as an operator
   * - should set approval status which can be queried via isApprovedForAll
   * - should be able to unset approval for an operator
   * - should emit an ApprovalForAll log
   */
  describe("setApprovalForAll/isApprovedForAll", function () {
    it("should revert if attempting to approve self as an operator", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, approver] = await ethers.getSigners();

      await expect(
        yulrc1155Contract
          .connect(approver)
          .setApprovalForAll(approver.address, true)
      ).to.be.reverted;
    });

    it("should set approval status which can be queried via isApprovedForAll", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, approver, operator] = await ethers.getSigners();

      // Confirm operator is not yet approved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(false);

      // Approve operator
      const setApprovalForAllTx = await yulrc1155Contract
        .connect(approver)
        .setApprovalForAll(operator.address, true);
      await setApprovalForAllTx.wait(1);

      // Confirm operator is now approved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(true);
    });

    it("should be able to unset approval for an operator", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, approver, operator] = await ethers.getSigners();

      // Approve operator
      const setApprovalForAllTrueTx = await yulrc1155Contract
        .connect(approver)
        .setApprovalForAll(operator.address, true);
      await setApprovalForAllTrueTx.wait(1);

      // Confirm operator is now approved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(true);

      // Disapprove operator
      const setApprovalForAllFalseTx = await yulrc1155Contract
        .connect(approver)
        .setApprovalForAll(operator.address, false);
      await setApprovalForAllFalseTx.wait(1);

      // Confirm operator is now disapproved
      expect(
        await yulrc1155Contract.isApprovedForAll(
          approver.address,
          operator.address
        )
      ).to.equal(false);
    });

    it("should emit an ApprovalForAll log", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, approver, operator] = await ethers.getSigners();

      await expect(
        await yulrc1155Contract
          .connect(approver)
          .setApprovalForAll(operator.address, true)
      )
        .to.emit(yulrc1155Contract, "ApprovalForAll")
        .withArgs(approver.address, operator.address, true);
    });
  });

  /**
   * safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)
   *
   * it:
   * - should revert when transferring more than the balance
   * - should revert when transferring to the zero address
   * - should revert when the operator is not approved by multiTokenHolder
   * - should revert when the receiver contract returns an unexpected value
   * - should revert when the receiver contract reverts
   * - should revert when the receiver does not implement the required function
   * - should debit the transferred balance from the sender
   * - should credit the transferred balance to the receiver
   * - should preserve existing balances that are not transferred by multiTokenHolder
   * - should succeed when the operator is approved by multiTokenHolder
   * - should preserve the operator's balances not involved in the transfer
   * - should succeed when calling onERC1155Received without data
   * - should succeed when calling onERC1155Received with data
   * - should emit a TransferSingle log
   */
  describe("safeTransferFrom", function () {
    const tokenId = 1990;
    const mintAmount = 9001;

    it("should revert when transferring more than the balance", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            tokenReceiver.address,
            tokenId,
            mintAmount + 1,
            DATA
          )
      ).to.be.reverted;
    });

    it("should revert when transferring to the zero address", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            ZERO_ADDRESS,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted;
    });

    it("should revert when the operator is not approved by multiTokenHolder", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      await expect(
        yulrc1155Contract
          .connect(tokenReceiver)
          .safeTransferFrom(
            tokenHolder.address,
            tokenReceiver.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted;
    });

    it("should revert when the receiver contract returns an unexpected value", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const { unexpectedValueContract } = await loadFixture(
        deployUnexpectedValueFixture
      );
      const [_, tokenHolder] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            unexpectedValueContract.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted;
    });

    it("should revert when the receiver contract reverts", async function () {
      // Setup: Use a receiver contract that reverts
      // Attempt to transfer tokens to the receiver contract

      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const { receiverRevertsContract } = await loadFixture(
        deployReceiverRevertsFixture
      );
      const [_, tokenHolder] = await ethers.getSigners();

      // Attempt to transfer tokens to the receiver contract
      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      // Verify that the transfer reverts
      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            receiverRevertsContract.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted;
    });

    it("should revert when the receiver does not implement the required function", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const { missingFunctionContract } = await loadFixture(
        deployMissingFunctionFixture
      );
      const [_, tokenHolder] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      await expect(
        yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            missingFunctionContract.address,
            tokenId,
            mintAmount,
            DATA
          )
      ).to.be.reverted;
    });

    it("should debit the transferred balance from the sender", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      // Transfer 123 tokens to receiver
      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          123,
          DATA
        );
      await safeTransferFromTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(mintAmount - 123);
    });

    it("should credit the transferred balance to the receiver", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      // Transfer 123 tokens to receiver
      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          123,
          DATA
        );
      await safeTransferFromTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(tokenReceiver.address, tokenId)
      ).to.equal(123);
    });

    it("should preserve existing balances that are not transferred by multiTokenHolder", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners();
      const tokenOneId = 123;
      const tokenTwoId = 456;

      const mintBatchTx = await yulrc1155Contract.mintBatch(
        tokenHolder.address,
        [tokenOneId, tokenTwoId],
        [mintAmount, mintAmount],
        DATA
      );
      await mintBatchTx.wait(1);

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenOneId,
          mintAmount,
          DATA
        );
      await safeTransferFromTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenTwoId)
      ).to.equal(mintAmount);
    });

    it("should succeed when the operator is approved by multiTokenHolder", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenOperator, tokenReceiver] =
        await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      // Approve `tokenOperator` to transfer on behalf of `tokenHolder`
      const setApprovalForAllTx = await yulrc1155Contract
        .connect(tokenHolder)
        .setApprovalForAll(tokenOperator.address, true);
      await setApprovalForAllTx.wait(1);

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenOperator)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          mintAmount,
          DATA
        );
      await safeTransferFromTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(0);

      expect(
        await yulrc1155Contract.balanceOf(tokenReceiver.address, tokenId)
      ).to.equal(mintAmount);
    });

    it("should preserve the operator's balances not involved in the transfer", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenOperator, tokenReceiver] =
        await ethers.getSigners();

      const mintToTokenHolderTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintToTokenHolderTx.wait(1);

      const mintToOperatorTx = await yulrc1155Contract.mint(
        tokenOperator.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintToOperatorTx.wait(1);

      // Approve `tokenOperator` to transfer on behalf of `tokenHolder`
      const setApprovalForAllTx = await yulrc1155Contract
        .connect(tokenHolder)
        .setApprovalForAll(tokenOperator.address, true);
      await setApprovalForAllTx.wait(1);

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenOperator)
        .safeTransferFrom(
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          mintAmount,
          DATA
        );
      await safeTransferFromTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(tokenHolder.address, tokenId)
      ).to.equal(0);

      expect(
        await yulrc1155Contract.balanceOf(tokenReceiver.address, tokenId)
      ).to.equal(mintAmount);

      expect(
        await yulrc1155Contract.balanceOf(tokenOperator.address, tokenId)
      ).to.equal(mintAmount);
    });

    it("should succeed when calling onERC1155Received without data", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const { erc1155ReceiverContract } = await loadFixture(
        deployERC1155ReceiverFixture
      );
      const [_, tokenHolder] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          erc1155ReceiverContract.address,
          tokenId,
          mintAmount,
          "0x00"
        );
      await safeTransferFromTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(
          erc1155ReceiverContract.address,
          tokenId
        )
      ).to.equal(mintAmount);
    });

    it("should succeed when calling onERC1155Received with data", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const { erc1155ReceiverContract } = await loadFixture(
        deployERC1155ReceiverFixtureTwo
      );
      const [_, tokenHolder] = await ethers.getSigners();

      const mintTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintTx.wait(1);

      const safeTransferFromTx = await yulrc1155Contract
        .connect(tokenHolder)
        .safeTransferFrom(
          tokenHolder.address,
          erc1155ReceiverContract.address,
          tokenId,
          mintAmount,
          DATA
        );
      await safeTransferFromTx.wait(1);

      expect(
        await yulrc1155Contract.balanceOf(
          erc1155ReceiverContract.address,
          tokenId
        )
      ).to.equal(mintAmount);
    });

    it("should emit a TransferSingle log", async function () {
      const { yulrc1155Contract } = await loadFixture(deployYULRC1155Fixture);
      const [_, tokenHolder, tokenReceiver] = await ethers.getSigners();

      const mintToTokenHolderTx = await yulrc1155Contract.mint(
        tokenHolder.address,
        tokenId,
        mintAmount,
        DATA
      );
      await mintToTokenHolderTx.wait(1);

      await expect(
        await yulrc1155Contract
          .connect(tokenHolder)
          .safeTransferFrom(
            tokenHolder.address,
            tokenReceiver.address,
            tokenId,
            mintAmount,
            DATA
          )
      )
        .to.emit(yulrc1155Contract, "TransferSingle")
        .withArgs(
          tokenHolder.address,
          tokenHolder.address,
          tokenReceiver.address,
          tokenId,
          mintAmount
        );
    });
  });
});
