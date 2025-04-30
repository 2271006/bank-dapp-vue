<template>
  <div id="app">
    <div class="container">
      <div class="col-12 col-md-6 offset-md-3 mt-4">
        <div class="card">
          <div class="card-header">
            <h6>Welcome to Bank2U</h6>
          </div>
          <div class="card-body">
            <button id="connectButton"
              v-if="!currentAccount"
              v-on:click="connectWallet"
              :disabled="connecting"
              class="btn btn-success">{{ (!connecting) ? 'Connect Metamask' : 'Connecting ... '}}</button>

            <div v-if="currentAccount">
              <div class="d-flex flex-column justify-content-center align-items-center mb-4">
                <div>
                  <b>My Balance in Bank</b>
                </div>
                <div class="d-flex flex-row">
                  <h2 class="m-0">{{ currentBalance }}</h2>
                  <small class="text-muted align-self-end mb-2 ml-1">ETH</small>
                </div>
              </div>

              <div class="form-group">
                <label for="deposit">Deposit</label>
                <div class="row">
                  <div class="input-group col-10">
                    <input type="number" id="deposit" 
                      :disabled="loading"
                      v-model="form.depositAmount" class="form-control"/>
                    <div class="input-group-append">
                      <span class="input-group-text" id="basic-addon2">ETH</span>
                    </div>
                  </div>
                  <button class="btn btn-success col-2 btn-sm"
                    :disabled="loading"
                    v-on:click.prevent="deposit">Deposit</button>
                </div>
              </div>

              <div class="form-group">
                <label for="withdraw">Withdraw</label>
                <div class="row">
                  <div class="input-group col-10">
                    <input type="number" id="withdraw" 
                      :disabled="loading"
                      v-model="form.withdrawalAmount" class="form-control"/>
                    <div class="input-group-append">
                      <span class="input-group-text" id="basic-addon2">ETH</span>
                    </div>
                  </div>
                  <button class="btn btn-danger col-2 btn-sm"
                    :disabled="loading"
                    v-on:click.prevent="withdraw">Withdraw</button>
                </div>
              </div>

              <!-- Deposit History -->
              <div class="form-group">
                <label>Deposit History</label>
                <ul>
                  <li v-for="(amount, index) in depositHistory" :key="index">
                    {{ formatEther(amount) }} ETH
                  </li>
                </ul>
              </div>
              <!-- End Deposit History -->

              <!-- Auto-Deposit and Reward Info -->
              <div class="form-group">
                <label>Auto-Deposit & Rewards</label>
                <p>Auto-deposit of 0.01 ETH every minute is active.</p>
                <p>Reward of 0.005 ETH issued every 30 seconds.</p>
              </div>
              <!-- End Auto-Deposit and Reward Info -->

            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ethers } from "ethers";
import ContractAbi from '../artifacts/contracts/Bank2U.sol/Bank2U.json';

export default {
  name: 'App',
  data () {
    return {
      contract: null,
      loading: false,
      connecting: false,
      currentAccount: null,
      currentBalance: 0,
      depositHistory: [], // deposit history
      form: {
        depositAmount: 0,
        withdrawalAmount: 0
      },
      autoDepositInterval: null, // auto-deposit
      rewardInterval: null // deposit rewards
    }
  },
  mounted () {
    const { ethereum } = window;

    if (ethereum) {
      const provider = new ethers.providers.Web3Provider(ethereum);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        '0x5FbDB2315678afecb367f032d93F642f64180aa3', // replace with your contract address
        ContractAbi.abi,
        signer
      );
      this.contract = contract;
    }
  },
  methods: {
    async connectWallet () {
      try {
        const { ethereum } = window;

        if (!ethereum) {
          console.log('Metamask not detected');
          return;
        }

        this.connecting = true;
        const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
        this.connecting = false;
        this.currentAccount = accounts[0];

        this.checkBalance();
        this.fetchDepositHistory(); // deposit history

        // Start auto-deposit every minute
        this.autoDepositInterval = setInterval(this.autoDeposit, 60000); // auto-deposit

        // Start reward issuance every 30 seconds
        this.rewardInterval = setInterval(this.issueReward, 30000); // deposit rewards

      } catch (error) {
        this.connecting = false;
        console.log('Error connecting to metamask', error);
      }
    },

    async deposit () {
      try {
        this.loading = true;
        const amount = parseFloat(this.form.depositAmount);
        if (amount < 0.01) {
          alert('Minimum deposit is 0.01 ETH'); // minimum deposit enforcement
          this.loading = false;
          return;
        }

        const options = {
          value: ethers.utils.parseEther(amount.toString())
        };

        const txn = await this.contract.deposit(options);
        await txn.wait();

        alert(`Successfully deposited ${amount} ETH to bank`);
        this.checkBalance();
        this.fetchDepositHistory(); // deposit history

        this.loading = false;
        this.form.depositAmount = 0;

      } catch (e) {
        console.log(e);
        this.loading = false;
        alert('Failed to deposit');
      }
    },

    async withdraw () {
      try {
        this.loading = true;
        const amount = parseFloat(this.form.withdrawalAmount);
        const txn = await this.contract.withdraw(
          ethers.utils.parseEther(amount.toString())
        );
        await txn.wait();

        alert(`Successfully withdrew ${amount} ETH from bank`);
        this.checkBalance();

        this.loading = false;
        this.form.withdrawalAmount = 0;
      } catch (e) {
        console.log(e);
        this.loading = false;
        alert('Failed to withdraw');
      }
    },

    async checkBalance () {
      this.loading = true;
      const balance = await this.contract.balance();
      this.currentBalance = ethers.utils.formatEther(balance);
      this.loading = false;
    },

    async fetchDepositHistory () {
      const history = await this.contract.getDepositHistory(); // deposit history
      this.depositHistory = history;
    },

    async autoDeposit () {
      try {
        const options = {
          value: ethers.utils.parseEther("0.01")
        };

        const txn = await this.contract.deposit(options);
        await txn.wait();

        console.log("Auto-deposit of 0.01 ETH completed"); // auto-deposit
        this.checkBalance();
        this.fetchDepositHistory(); // deposit history
      } catch (e) {
        console.log("Auto-deposit failed", e); // auto-deposit
      }
    },

    async issueReward () {
      try {
        const options = {
          value: ethers.utils.parseEther("0.005")
        };

        const txn = await this.contract.deposit(options);
        await txn.wait();

        console.log("Reward of 0.005 ETH issued"); // deposit rewards
        this.checkBalance();
        this.fetchDepositHistory(); // deposit history
      } catch (e) {
        console.log("Reward issuance failed", e); // deposit rewards
      }
    },

    formatEther (wei) {
      return ethers.utils.formatEther(wei);
    }
  },
  beforeDestroy () {
    clearInterval(this.autoDepositInterval); // auto-deposit
    clearInterval(this.rewardInterval); // deposit rewards
  }
}
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap');

html, body, p, span, div {
  font-family: 'Roboto', sans-serif;
}

body {
  background-color: #242424;
}
</style>
