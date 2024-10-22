// 引入 Web3Modal 和 ethers.js
const Web3Modal = window.Web3Modal.default;
const ethers = window.ethers;

let web3Modal;
let provider;
let signer;
let selectedAccount = null;

// 初始化 Web3Modal
function init() {
    console.log("Initializing Web3Modal");
    
    const providerOptions = {
        // walletconnect: {
        //     package: window.WalletConnectProvider.default,
        //     options: {
        //         infuraId: '5a6c493631254edaa4011e43e3c879f9' // 替换为你的 Infura ID
        //     }
        // }
    };  // 当前仅使用 MetaMask，无需配置额外的选项

    web3Modal = new Web3Modal({
        cacheProvider: false, // 可选：缓存上次使用的 provider
        providerOptions, // 传入 provider 选项
    });
}

// 连接钱包
async function connectWallet() {
    try {
        console.log("Opening Web3Modal to connect wallet...");
        provider = await web3Modal.connect();

        // 创建 ethers.js provider
        const ethersProvider = new ethers.providers.Web3Provider(provider);

        // 获取 signer（签名者）以与钱包交互
        signer = ethersProvider.getSigner();
        selectedAccount = await signer.getAddress();

        // 显示钱包地址
        document.getElementById("walletAddress").innerText = `My Wallet Address: ${selectedAccount}`;

        // 显示断开按钮，隐藏连接按钮
        document.getElementById("disconnectWallet").style.display = "block";
        document.getElementById("connectWallet").style.display = "none";

        // 监听账户切换（MetaMask）
        provider.on("accountsChanged", (accounts) => {
            selectedAccount = accounts[0];
            document.getElementById("walletAddress").innerText = `Connected Wallet Address: ${selectedAccount}`;
        });

        // 监听网络切换
        provider.on("chainChanged", (chainId) => {
            console.log(`Network changed to ${chainId}`);
        });

    } catch (error) {
        console.error("Could not connect to wallet:", error);
    }
}

// 断开钱包连接
function disconnectWallet() {
    console.log("Disconnecting wallet...");
    web3Modal.clearCachedProvider();
    provider = null;
    selectedAccount = null;

    // 清空页面上的钱包地址
    document.getElementById("walletAddress").innerText = "";

    // 显示连接按钮，隐藏断开按钮
    document.getElementById("disconnectWallet").style.display = "none";
    document.getElementById("connectWallet").style.display = "block";
}

// 当页面加载完毕后初始化 Web3Modal
window.addEventListener('DOMContentLoaded', () => {
    init();

    // 绑定按钮事件
    document.getElementById("connectWallet").addEventListener("click", connectWallet);
    document.getElementById("disconnectWallet").addEventListener("click", disconnectWallet);
});
