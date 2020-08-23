using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace hello_world.Controllers.UnitTests
{
    [TestClass]
    public class HomeController_UnitTest
    {
        private readonly HomeController _homeController;

        public HomeController_UnitTest()
        {
            _homeController = new HomeController(null);
        }

        [TestMethod]
        public void CheckTrue_ReturnTrue()
        {
            var result = _homeController.ReturnTrue();

            Assert.IsTrue(result, "Should return true.");
        }
    }
}