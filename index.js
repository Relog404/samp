const { Client, GatewayIntentBits } = require('discord.js');
const express = require('express');
const app = express();

const CONFIG = {
    TOKEN: 'MTUyODg4NDY5MDE2ODMyMDEzMA.GQFwXs.kp-9Dw7UfoDX61mbFkIufOnvh40ZpqoaTEWOHg',
    GUILD_ID: '1176463454756950016',
    SECRET_KEY: 'MySuperSecretKey2024!',
    PORT: process.env.PORT || 8080
};

// Соответствие фракций и ролей
const ROLE_MAPPING = {
    '1': '1528892679646216232',
    '2': '1528892791373955173',
    '3': '1528891990413148210',
};

// Хранилище: код → { playerid, faction, timestamp }
const pendingCodes = new Map();

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMembers,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.DirectMessages
    ]
});

client.once('ready', () => {
    console.log(`✅ Бот ${client.user.tag} запущен`);
    console.log(`📋 Доступно фракций: ${Object.keys(ROLE_MAPPING).length}`);
});

// ==========================================
// ЛИЧНЫЕ СООБЩЕНИЯ — ОСНОВНАЯ ЛОГИКА
// ==========================================
client.on('messageCreate', async (message) => {
    if (message.author.bot) return;
    if (message.guild) return; // Только ЛС

    const args = message.content.trim().split(' ');
    if (args[0].toLowerCase() !== '!link' || args.length !== 2) {
        return;
    }

    const code = args[1];
    const discord_id = message.author.id;

    // Проверяем код
    const data = pendingCodes.get(code);
    if (!data) {
        return message.reply('❌ Неверный код. Запроси новый через /link в игре.');
    }

    // Проверяем срок (2 минуты)
    if (Date.now() - data.timestamp > 120000) {
        pendingCodes.delete(code);
        return message.reply('❌ Код истёк. Запроси новый.');
    }

    const faction_id = String(data.faction);
    const role_id = ROLE_MAPPING[faction_id];

    if (!role_id) {
        pendingCodes.delete(code);
        return message.reply(`❌ Нет роли для твоей фракции (${faction_id}). Обратись к администратору.`);
    }

    try {
        const guild = await client.guilds.fetch(CONFIG.GUILD_ID);
        const member = await guild.members.fetch(discord_id);
        const role = await guild.roles.fetch(role_id);

        if (!member) {
            return message.reply('❌ Ты не на сервере! Зайди на Discord сервер.');
        }

        if (!role) {
            return message.reply('❌ Роль не найдена. Обратись к администратору.');
        }

        // ВЫДАЁМ РОЛЬ!
        await member.roles.add(role);
        console.log(`✅ ${message.author.tag} → фракция ${faction_id} → роль ${role.name}`);

        // Удаляем код
        pendingCodes.delete(code);

        await message.reply(`✅ Роль **${role.name}** выдана! Добро пожаловать на сервер!`);

    } catch (error) {
        console.error('❌ Ошибка:', error.message);
        await message.reply(`❌ Ошибка: ${error.message}`);
    }
});

// ==========================================
// HTTP ЭНДПОИНТЫ (для приёма кодов от SAMP)
// ==========================================
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// SAMP сервер сообщает боту код + фракцию
app.get('/add-code', (req, res) => {
    const { code, player, faction, key } = req.query;

    if (key !== CONFIG.SECRET_KEY) {
        return res.status(403).send('❌ Неверный ключ');
    }

    if (!code || !player) {
        return res.status(400).send('❌ Нет code или player');
    }

    pendingCodes.set(code, {
        playerid: parseInt(player),
        faction: parseInt(faction) || 0,
        timestamp: Date.now()
    });

    console.log(`📝 Код ${code} зарегистрирован (фракция ${faction})`);
    res.send('✅ Код принят');
});

// Проверка статуса
app.get('/status', (req, res) => res.send('✅ Бот работает'));

app.listen(CONFIG.PORT, () => {
    console.log(`✅ Сервер на порту ${CONFIG.PORT}`);
});

client.login(CONFIG.TOKEN);